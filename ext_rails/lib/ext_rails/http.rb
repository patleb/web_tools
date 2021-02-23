module HTTP
  def self.no_ssl_client
    (ctx = OpenSSL::SSL::SSLContext.new).verify_mode = OpenSSL::SSL::VERIFY_NONE
    http = HTTP::Client.new(ssl_context: ctx)
    if block_given?
      yield http
    else
      http
    end
  end
end
