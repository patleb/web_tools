class LetsEncrypt < Credential
  class InvalidEnv < ::StandardError; end
  class AcmeTimeout < ::StandardError; end
  class AcmeInvalid < ::StandardError; end
  class AcmeBadName < ::StandardError; end

  scope :renewable, -> { where((column(:expires_at) - 1.month) < Time.current) }
  scope :current_host, -> { where(id: default_id) }

  json_attribute(
    kid: :string,
    certificate: :encrypted,
    intermediates: :encrypted,
    private_key: :encrypted,
  )

  after_initialize :set_defaults

  def self.default_id
    "#{Setting[:server_host]}/#{ACME_CHALLENGE}"
  end

  def self.find_or_initialize(kid = nil)
    current_host.take || new(kid: kid).initialize_kid
  end

  def self.find_renewable
    current_host.renewable.take
  end

  def self.find_by_token!(token)
    current_host.where(token: token).take!
  end

  def initialize_kid
    return self if kid.present?
    update! kid: acme.new_account(contact: "mailto:#{Setting[:mail_to].first}", terms_of_service_agreed: true).kid
    self
  end

  def create
    create_challenge
    create_certificate
  end
  alias_method :renew, :create

  protected

  def create_challenge
    challenge = acme_order.authorizations.first.http
    update! token: extract_token(challenge), challenge: challenge.file_content
    challenge.request_validation
    checks = 0
    while challenge.status == 'pending'
      raise AcmeTimeout if (checks += 1) > 30
      sleep 1
      challenge.reload
    end
    unless challenge.status == 'valid'
      raise AcmeInvalid, "Status: [#{challenge.status}]"
    end
  rescue Acme::Client::Error => exception
    @retries ||= 0
    if exception.is_a?(Acme::Client::Error::BadNonce) && (@retries += 1) <= 5
      sleep 1
      retry
    else
      raise
    end
  end

  def create_certificate
    acme_order.finalize(
      csr: Acme::Client::CertificateRequest.new(private_key: OpenSSL::PKey::RSA.new(decrypted(:private_key)), subject: {
        common_name: server_host
      })
    )
    while acme_order.status == 'processing'
      sleep 1
    end
    certificates = acme_order.certificate.split("\n\n")
    certificate = OpenSSL::X509::Certificate.new(certificates.shift)
    update! certificate: certificate.to_pem, intermediates: certificates.join("\n\n"), expires_at: certificate.not_after
  end

  private

  def extract_token(challenge)
    raise AcmeBadName unless challenge.filename.start_with? ACME_CHALLENGE
    challenge.filename.delete_prefix(ACME_CHALLENGE).delete_prefix('/')
  end

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
      Acme::Client.new(kid: kid, private_key: OpenSSL::PKey::RSA.new(Setting[:owner_private_key]), directory: directory)
    end
  end

  def server_host
    @server_host ||= id.split('/').first
  end

  def set_defaults
    self.id ||= self.class.default_id
    self.private_key ||= OpenSSL::PKey::RSA.new(4096).to_s
  end
end
