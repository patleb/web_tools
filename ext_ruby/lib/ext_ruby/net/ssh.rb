# https://github.com/net-ssh/net-ssh/pull/811
module Net
  module SSH
    module Authentication
      Certificate.class_eval do
        def ssh_do_sign(data, sig_alg=nil)
          key.ssh_do_sign(data, sig_alg)
        end
      end

      module ED25519
        PrivKey.class_eval do
          def ssh_do_sign(data, sig_alg=nil)
            @sign_key.sign(data)
          end
        end
      end

      KeyManager.class_eval do
        def sign(identity, data, sig_alg=nil)
          info = known_identities[identity] or raise KeyManagerError, "the given identity is unknown to the key manager"

          if info[:key].nil? && info[:from] == :file
            begin
              info[:key] = KeyFactory.load_private_key(info[:file], options[:passphrase], !options[:non_interactive], options[:password_prompt])
            rescue OpenSSL::OpenSSLError, Exception => e
              raise KeyManagerError, "the given identity is known, but the private key could not be loaded: #{e.class} (#{e.message})"
            end
          end

          if info[:key]
            if sig_alg.nil?
              signed = info[:key].ssh_do_sign(data.to_s)
              sig_alg = identity.ssh_signature_type
            else
              signed = info[:key].ssh_do_sign(data.to_s, sig_alg)
            end
            return Net::SSH::Buffer.from(:string, sig_alg,
              :mstring, signed).to_s
          end

          if info[:from] == :agent
            raise KeyManagerError, "the agent is no longer available" unless agent

            case sig_alg
            when "rsa-sha2-512"
              return agent.sign(info[:identity], data.to_s, Net::SSH::Authentication::Agent::SSH_AGENT_RSA_SHA2_512)
            when "rsa-sha2-256"
              return agent.sign(info[:identity], data.to_s, Net::SSH::Authentication::Agent::SSH_AGENT_RSA_SHA2_256)
            else
              return agent.sign(info[:identity], data.to_s)
            end
          end

          raise KeyManagerError, "[BUG] can't determine identity origin (#{info.inspect})"
        end
      end

      module Methods
        Abstract.class_eval do
          # So far only affects algorithms used for rsa keys, but can be
          # extended to other keys, e.g after reading of
          # PubkeyAcceptedAlgorithms option from ssh_config file is implemented.
          attr_reader :pubkey_algorithms

          def initialize(session, options={})
            @session = session
            @key_manager = options[:key_manager]
            @options = options
            @prompt = options[:password_prompt]
            @pubkey_algorithms = options[:pubkey_algorithms] \
              || %w[rsa-sha2-256-cert-v01@openssh.com
                    ssh-rsa-cert-v01@openssh.com
                    rsa-sha2-256
                    ssh-rsa]
            self.logger = session.logger
          end
        end

        Publickey.class_eval do
          private

          def build_request(pub_key, username, next_service, alg, has_sig)
            blob = Net::SSH::Buffer.new
            blob.write_key pub_key

            userauth_request(username, next_service, "publickey", has_sig,
              alg, blob.to_s)
          end

          def send_request(pub_key, username, next_service, alg, signature=nil)
            msg = build_request(pub_key, username, next_service, alg,
              !signature.nil?)
            msg.write_string(signature) if signature
            send_message(msg)
          end

          def authenticate_with_alg(identity, next_service, username, alg, sig_alg=nil)
            debug { "trying publickey (#{identity.fingerprint})" }
            send_request(identity, username, next_service, alg)

            message = session.next_message

            case message.type
            when Authentication::Constants::USERAUTH_PK_OK
              buffer = build_request(identity, username, next_service, alg,
                true)
              sig_data = Net::SSH::Buffer.new
              sig_data.write_string(session_id)
              sig_data.append(buffer.to_s)

              sig_blob = key_manager.sign(identity, sig_data, sig_alg)

              send_request(identity, username, next_service, alg, sig_blob.to_s)
              message = session.next_message

              case message.type
              when Authentication::Constants::USERAUTH_SUCCESS
                debug { "publickey succeeded (#{identity.fingerprint})" }
                return true
              when Authentication::Constants::USERAUTH_FAILURE
                debug { "publickey failed (#{identity.fingerprint})" }

                raise Net::SSH::Authentication::DisallowedMethod unless
                  message[:authentications].split(/,/).include? 'publickey'

                return false
              else
                raise Net::SSH::Exception,
                  "unexpected server response to USERAUTH_REQUEST: #{message.type} (#{message.inspect})"
              end

            when Authentication::Constants::USERAUTH_FAILURE
              return false
            when Authentication::Constants::USERAUTH_SUCCESS
              return true

            else
              raise Net::SSH::Exception, "unexpected reply to USERAUTH_REQUEST: #{message.type} (#{message.inspect})"
            end
          end

          def authenticate_with(identity, next_service, username)
            type = identity.ssh_type
            if type == "ssh-rsa"
              pubkey_algorithms.each do |pk_alg|
                case pk_alg
                when "rsa-sha2-512", "rsa-sha2-256", "ssh-rsa"
                  if authenticate_with_alg(identity, next_service, username, pk_alg, pk_alg)
                    # success
                    return true
                  end
                end
              end
            elsif type == "ssh-rsa-cert-v01@openssh.com"
              pubkey_algorithms.each do |pk_alg|
                case pk_alg
                when "rsa-sha2-512-cert-v01@openssh.com"
                  if authenticate_with_alg(identity, next_service, username, pk_alg, "rsa-sha2-512")
                    # success
                    return true
                  end
                when "rsa-sha2-256-cert-v01@openssh.com"
                  if authenticate_with_alg(identity, next_service, username, pk_alg, "rsa-sha2-256")
                    # success
                    return true
                  end
                when "ssh-rsa-cert-v01@openssh.com"
                  if authenticate_with_alg(identity, next_service, username, pk_alg)
                    # success
                    return true
                  end
                end
              end
            elsif authenticate_with_alg(identity, next_service, username, type)
              # success
              return true
            end
            # failure
            return false
          end
        end
      end

      Session.class_eval do
        def authenticate(next_service, username, password=nil)
          debug { "beginning authentication of `#{username}'" }

          transport.send_message(transport.service_request("ssh-userauth"))
          expect_message(Transport::Constants::SERVICE_ACCEPT)

          key_manager = KeyManager.new(logger, options)
          keys.each { |key| key_manager.add(key) } unless keys.empty?
          keycerts.each { |keycert| key_manager.add_keycert(keycert) } unless keycerts.empty?
          key_data.each { |key2| key_manager.add_key_data(key2) } unless key_data.empty?
          default_keys.each { |key| key_manager.add(key) } unless options.key?(:keys) || options.key?(:key_data)

          attempted = []

          @auth_methods.each do |name|
            next unless @allowed_auth_methods.include?(name)

            attempted << name

            debug { "trying #{name}" }
            begin
              auth_class = Methods.const_get(name.split(/\W+/).map { |p| p.capitalize }.join)
              method = auth_class.new(self,
                key_manager: key_manager, password_prompt: options[:password_prompt],
                pubkey_algorithms: options[:pubkey_algorithms] || nil)
            rescue NameError
              debug {"Mechanism #{name} was requested, but isn't a known type.  Ignoring it."}
              next
            end

            return true if method.authenticate(next_service, username, password)
          rescue Net::SSH::Authentication::DisallowedMethod
          end

          error { "all authorization methods failed (tried #{attempted.join(', ')})" }
          return false
        ensure
          key_manager.finish if key_manager
        end
      end
    end
  end
end

module OpenSSL
  module PKey
    RSA.class_eval do
      def ssh_do_sign(data, sig_alg=nil)
        digester =
          if sig_alg == "rsa-sha2-512"
            OpenSSL::Digest::SHA512.new
          elsif sig_alg == "rsa-sha2-256"
            OpenSSL::Digest::SHA256.new
          else
            OpenSSL::Digest::SHA1.new
          end
        sign(digester, data)
      end
    end

    DSA.class_eval do
      def ssh_do_sign(data, sig_alg=nil)
        sig = sign(OpenSSL::Digest::SHA1.new, data)
        a1sig = OpenSSL::ASN1.decode(sig)

        sig_r = a1sig.value[0].value.to_s(2)
        sig_s = a1sig.value[1].value.to_s(2)

        raise OpenSSL::PKey::DSAError, "bad sig size" if sig_r.length > 20 || sig_s.length > 20

        sig_r = "\0" * (20 - sig_r.length) + sig_r if sig_r.length < 20
        sig_s = "\0" * (20 - sig_s.length) + sig_s if sig_s.length < 20

        return sig_r + sig_s
      end
    end

    EC.class_eval do
      def ssh_do_sign(data, sig_alg=nil)
        digest = digester.digest(data)
        sig = dsa_sign_asn1(digest)
        a1sig = OpenSSL::ASN1.decode(sig)

        sig_r = a1sig.value[0].value
        sig_s = a1sig.value[1].value

        Net::SSH::Buffer.from(:bignum, sig_r, :bignum, sig_s).to_s
      end
    end
  end
end
