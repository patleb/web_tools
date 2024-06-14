if defined?(WEBrick) && Rails.env.local?
  require 'webrick/httpserver'

  WEBrick::HTTPServer.class_eval do
    def access_log(config, req, res)
      # so assets don't log
    end
  end
end
