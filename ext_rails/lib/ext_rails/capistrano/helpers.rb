module ExtRails
  module Helpers
    def pgrest_restart
      execute :sudo, "systemctl restart pgrest"
    end

    def pgrest_reload
      test :sudo, "systemctl reload pgrest"
    end

    %w(start stop restart reload).each do |action|
      define_method "nginx_#{action}" do
        execute :sudo, :systemctl, action, 'nginx'
      end
    end

    def nginx_app_push
      if test("[ -f /etc/nginx/sites-available/#{fetch(:deploy_dir)} ]")
        within '/etc/nginx/sites-available' do
          execute :sudo, :rm, '-f', fetch(:deploy_dir)
        end
        nginx_reload
      end
    end

    def monit_restart
      execute :sudo, "systemctl restart monit"
    end

    def monit_reload
      test :sudo, "systemctl reload monit"
    end

    def monit_push
      template_push 'monitrc', monitrc
      execute :sudo, :chown, 'root:root', monitrc
      execute :sudo, :chmod, 600, monitrc
    end

    def monitrc
      cap.os.centos? ? '/etc/monitrc' : '/etc/monit/monitrc'
    end

    def url_for(path, **params)
      path = path[0] == '/' ? path[1..-1] : path
      params = params.any? ? "?#{params.to_param}" : ''
      "https://#{fetch(:server)}/#{path}#{params}"
    end
  end
end
