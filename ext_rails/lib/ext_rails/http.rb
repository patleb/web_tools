module HTTP
  def self.no_ssl_client(host, keep_alive: 5)
    HTTP.persistent(host, timeout: keep_alive) do |http|
      (ctx = OpenSSL::SSL::SSLContext.new).verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.default_options = http.default_options.with_ssl_context ctx
      yield http
    end
  end
end
