# NOTE useful for a local server with only its own desktop browser as client
module ActionController::WithDispatch
  extend ActiveSupport::Concern

  class_methods do
    def dispatch_now(url_or_controller, action = nil, params: {}, request_params: {}, session: nil, local: nil)
      params = params.with_indifferent_access
      if request_params.has_key? :_method
        params[:method] = request_params[:_method] || 'post'
      end
      http_method = (params[:method] ||= :get).to_s.upcase
      if url_or_controller.is_a? String
        uri, query_params = Rack::Utils.parse_url(url_or_controller)
        path_params = recognize_path(uri.path, params.merge!(query_params))

        controller_name = "#{path_params[:controller].underscore.camelize}Controller"
        controller      = controller_name.to_const!
        action        ||= path_params[:action] || 'index'
      else
        controller  = url_or_controller
      end
      request_env = {
        'rack.input' => '',
        'QUERY_STRING' => uri&.query,
        'REQUEST_METHOD' => http_method,
        'REQUEST_PATH' => uri&.path,
        'REQUEST_URI' => url_or_controller,
        'PATH_INFO' => uri&.path,
        'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest',
        'HTTPS' => uri&.scheme == 'https' ? 'on' : 'off',
        'HTTP_HOST' => uri&.host,
        'REMOTE_ADDR' => '127.0.0.1',
        'SERVER_NAME' => uri&.hostname,
        'SERVER_PORT' => uri&.port,
        'SERVER_PROTOCOL' => 'HTTP/1.1',
        'rack.url_scheme' => uri&.scheme,
        'action_dispatch.remote_ip' => '127.0.0.1',
        'action_dispatch.request.query_parameters' => query_params,
        'action_dispatch.request.request_parameters' => request_params,
        'action_dispatch.request.path_parameters' => path_params,
        'action_dispatch.request.parameters' => params.merge!(request_params).merge!(path_params || {}),
      }.compact
      request_env['rack.session'] = session if session
      request = ActionDispatch::Request.new(request_env)
      response = controller.make_response! request

      old_local = controller.local
      controller.local = true if local
      begin
        result = controller.dispatch(action, request, response) # [status, headers, body]
        url_or_controller.is_a?(String) ? result : request.controller_instance
      ensure
        controller.local = old_local
      end
    end

    def recognize_path(path, options)
      begin
        recognized_path = Rails.application.routes.recognize_path(path, options)
      rescue ActionController::RoutingError => e
        unless e.message.start_with? 'No route matches'
          raise
        end
      end

      if recognized_path.nil? || recognized_path.except(:not_found) == { controller: 'application', action: 'render_404' }
        Rails::Engine.subclasses.each do |engine|
          mounted_engine = Rails.application.routes.routes.find{ |r| r.app.app == engine }
          next unless mounted_engine

          path_for_engine = path.sub(/^#{mounted_engine.path.spec}/, '')
          begin
            recognized_path = engine.routes.recognize_path(path_for_engine, options)
            break
          rescue ActionController::RoutingError
            # do nothing
          end
        end
      end

      unless recognized_path&.has_key? :controller
        raise ActionController::RoutingError, "No route matches [#{path}]"
      end

      recognized_path
    end
  end
end
