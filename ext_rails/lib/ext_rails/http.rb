module HTTP
  def self.local_client(base_url:, basic_auth: false, keep_alive: 5)
    base_uri = HTTP::URI.parse(base_url)
    origin, ssl = base_uri.origin, base_uri.https?

    if block_given?
      HTTP.persistent(origin, timeout: keep_alive) do |http|
        yield secure_local_client(http, ssl, basic_auth)
      end
    else
      http = HTTP.persistent(origin, timeout: keep_alive)
      secure_local_client(http, ssl, basic_auth)
    end
  end

  private

  def self.secure_local_client(http, ssl, basic_auth)
    if ssl
      (ctx = OpenSSL::SSL::SSLContext.new).verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.default_options = http.default_options.with_ssl_context ctx
    end
    if basic_auth
      deployer = Dir.pwd.match(/home\/(\w+)\//)[1]
      http = http.basic_auth(user: deployer, pass: Setting[:deployer_password])
    end
    http
  end
end
