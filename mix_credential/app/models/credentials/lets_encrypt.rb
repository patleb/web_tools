module Credentials
  class LetsEncrypt < Credential
    class InvalidEnv < ::StandardError; end
    class InvalidStatus < ::StandardError; end

    scope :renewable, -> { where((column(:expires_at) - 30.days) < Time.current) }
    scope :current_host, -> { where(id: default_id) }

    json_attribute(
      email: :string,
      kid: :string,
      key: :encrypted,
      crt: :encrypted,
    )

    after_initialize do
      self.id ||= self.class.default_id
      self.key ||= OpenSSL::PKey::RSA.new(4096).to_s
    end

    def self.default_id
      "#{Setting[:server_host]}/#{ACME_CHALLENGE}"
    end

    def self.find_or_initialize(kid = nil)
      find_current || new(kid: kid).initialize_account
    end

    def self.find_current
      current_host.take
    end

    def self.find_current!
      current_host.take!
    end

    def self.find_renewable
      current_host.renewable.take
    end

    def self.find_by_token!(token)
      current_host.where(token: token).take!
    end

    def initialize_account
      return self if (contact = Setting[:mail_to].first) == email
      options = { contact: "mailto:#{contact}", terms_of_service_agreed: true }
      account = email ? acme.account_update(options) : acme.new_account(options)
      update! email: contact, kid: account.kid
      self
    end

    def create
      create_challenge
      create_certificate
    end
    alias_method :renew, :create

    def revoke
      if acme.revoke certificate: decrypted(:crt)
        update! expires_at: Time.current
      end
    end

    def server_host
      @server_host ||= id.split('/').first
    end

    protected

    def create_challenge
      challenge = acme_order.authorizations.first.http
      update! token: challenge.token, challenge: challenge.file_content
      challenge.request_validation
      while challenge.status == 'pending'
        sleep 2
        challenge.reload
      end
      unless challenge.status == 'valid'
        raise InvalidStatus, "Status: [#{challenge.status}]"
      end
    end

    def create_certificate
      private_key = OpenSSL::PKey::RSA.new(decrypted(:key))
      csr = Acme::Client::CertificateRequest.new(private_key: private_key, subject: { common_name: server_host })
      acme_order.finalize(csr: csr)
      while acme_order.status == 'processing'
        sleep 1
        acme_order.reload
      end
      update! crt: acme_order.certificate, expires_at: 90.days.from_now
    end

    def not_after
      OpenSSL::X509::Certificate.new(decrypted(:crt).split("\n\n").first).not_after
    end

    private

    def acme_order
      @acme_order ||= acme.new_order(identifiers: [server_host])
    end

    def acme
      @acme ||= begin
        directory = case
        when Rails.env.production? then 'https://acme-v02.api.letsencrypt.org/directory'
        when Rails.env.staging?    then 'https://acme-staging-v02.api.letsencrypt.org/directory'
        else raise InvalidEnv
        end
        private_key = OpenSSL::PKey::RSA.new(Setting[:owner_private_key])
        Acme::Client.new(kid: kid, private_key: private_key, directory: directory, bad_nonce_retry: 5)
      end
    end
  end
end
