module Sunzistrano
  Cli.class_eval do
    desc 'firewall [STAGE] [--disable]', 'Enable/Disable SSH firewall limit'
    method_options disable: false
    def firewall(stage)
      with_context(stage) do
        if sun.disable
          run_command :disable_firewall_cmd, sun.server_host
        else
          run_command :enable_firewall_cmd, sun.server_host
        end
      end
    end

    no_tasks do
      alias_method :before_role_without_firewall, :before_role
      def before_role
        before_role_without_firewall
        return unless sun.cloud_cluster
        run_command :disable_firewall_cmd, sun.server_host
      end

      alias_method :after_role_without_firewall, :after_role
      def after_role
        after_role_without_firewall
        return unless sun.cloud_cluster
        run_command :enable_firewall_cmd, sun.server_host
      end

      private

      def disable_firewall_cmd(server)
        remote_cmd server, 'command -v ufw >/dev/null && sudo ufw delete limit ssh && sudo ufw allow ssh', proxy: false
      end

      def enable_firewall_cmd(server)
        remote_cmd server, 'command -v ufw >/dev/null && sudo ufw limit ssh', proxy: false
      end
    end
  end
end
