if defined?(WEBrick) && Rails::Env.dev_or_test?
  require 'webrick/httpserver'
  require 'rack/handler/webrick'

  WEBrick::HTTPServer.class_eval do
    def access_log(config, req, res)
      # so assets don't log
    end
  end

  Rack::Handler::WEBrick.class_eval do
    def self.shutdown
      @server&.shutdown
      @server = nil
    end
  end
end
