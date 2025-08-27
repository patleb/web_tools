module Sunzistrano
  Cli.class_eval do
    desc 'console [STAGE] [--host] [--sudo] [--sandbox]', 'Start a rails console'
    method_options host: :string, sudo: false, sandbox: false
    def console(stage) = do_console(stage)

    no_tasks do
      def do_console(stage)
        with_context(stage, :deploy) do
          raise '--host is required for cluster usage' if sun.server_cluster && options.host.blank?
          exec <<-SH.squish
            #{ssh_virtual_key}
            #{ssh_cmd} -t #{sun.ssh_user}@#{options.host.presence || sun.server_host} #{ssh_proxy} '#{console_remote_cmd}'
          SH
        end
      end

      def console_remote_cmd
        environment = ["RAILS_ENV=#{sun.env}", "RAILS_APP=#{sun.app}"]
        if sun.sudo
          rbenv_sudo = "rbenv sudo #{environment.join(' ')}"
        else
          context = environment.map{ |value| "export #{value};" }.join(' ')
        end
        path = "cd #{sun.deploy_path :current};"
        sandbox = '--sandbox' if sun.sandbox
        command = "bin/rails console #{sandbox}"
        <<-SH.squish
          #{Sh.rbenv_ruby} #{path} #{rbenv_sudo} #{context} #{command}
        SH
      end
    end
  end
end
