module Sunzistrano
  Cli.class_eval do
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
        limit_firewall_cmd server, delete: true
      end

      def enable_firewall_cmd(server)
        limit_firewall_cmd server
      end

      def limit_firewall_cmd(server, delete: false)
        remote_cmd server, "command -v ufw >/dev/null && sudo ufw#{' delete' if delete} limit ssh", proxy: false
      end
    end
  end
end
