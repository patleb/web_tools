module MixServer
  module Helpers
    def pgrest_reload
      test :sudo, "systemctl reload pgrest"
    end

    def pgrest_restart
      execute :sudo, "systemctl restart pgrest"
    end

    def try_nginx_reload
      unless nginx_reload
        error "Could not reload Nginx, trying restart."
        nginx_restart
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

    def monit_reload
      test :sudo, "systemctl reload monit"
    end

    def monit_restart
      execute :sudo, "systemctl restart monit"
    end

    def monit_push
      template_push 'monitrc', monitrc
      execute :sudo, :chown, 'root:root', monitrc
      execute :sudo, :chmod, 600, monitrc
    end

    def monitrc
      '/etc/monit/monitrc'
    end

    def url_for(path, **params)
      path = path[0] == '/' ? path[1..-1] : path
      params = params.any? ? "?#{params.to_param}" : ''
      "https://#{fetch(:server)}/#{path}#{params}"
    end
  end
end
