module MixServer
  module Helpers
    def pgrest_reload
      test :sudo, "systemctl reload pgrest"
    end

    def pgrest_restart
      execute :sudo, "systemctl restart pgrest"
    end

    def nginx_reload!
      unless nginx_reload
        error "Could not reload Nginx, trying start."
        nginx_start
      end
    end

    def nginx_reload
      test :sudo, "systemctl reload nginx"
    end

    %w(start stop restart).each do |action|
      define_method "nginx_#{action}" do
        execute :sudo, :systemctl, action, 'nginx'
      end
    end

    def url_for(path, ssl: true, **params)
      path = path[0] == '/' ? path[1..-1] : path
      params = params.any? ? "?#{params.to_param}" : ''
      "http#{'s' if ssl}://#{fetch(:server)}/#{path}#{params}"
    end
  end
end
