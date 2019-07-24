module ActionDispatch
  class IFrame
    def initialize(app)
      @app = app
    end

    def call(env)
      if (params = Rack::Request.new(env).params)
        # This was using an iframe transport, and is therefore an XHR
        # This is required if we're going to override the http_accept
        if params['X-Requested-With'] == 'IFrame'
          env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
        end

        # Override the accepted format, because it isn't what we really want
        if params['X-HTTP-Accept']
          env['HTTP_ACCEPT'] = params['X-HTTP-Accept']
        end
      end

      @app.call(env)
    end
  end
end
