module Sunzistrano
  Cli.class_eval do
    desc 'rake [stage] [task] [--sudo] [--nohup] [--verbose] [--kill]', 'Execute a rake task'
    method_options sudo: false, nohup: false, verbose: false, kill: false
    def rake(stage, task)
      do_rake(stage, task)
    end

    no_tasks do
      def do_rake(stage, task)
        with_context(stage, :deploy, task: task) do
          run_job_cmd :rake
        end
      end

      def rake_remote_cmd
        environment = ["RAKE_OUTPUT=#{sun.verbose.to_b}", "RAILS_ENV=#{sun.env}", "RAILS_APP=#{sun.app}"]
        rbenv_ruby = "#{Sh.rbenv_export}; #{Sh.rbenv_init};"
        if sun.sudo
          rbenv_sudo = "rbenv sudo #{environment.join(' ')}"
        else
          context = environment.map{ |value| "export #{value};" }.join(' ')
        end
        path = "cd #{sun.deploy_path :current};"
        command = %{bin/rake '#{sun.task.escape_single_quotes.escape_spaces}'}
        if sun.nohup
          filename = nohup_basename(command)
          command = "#{command} >> log/#{filename}.log 2>&1 & sleep 1 && echo $! > tmp/pids/#{filename}.pid"
          <<-SH.squish
            #{rbenv_ruby} #{context} #{path} nohup #{rbenv_sudo} #{command}
          SH
        elsif sun.kill
          filename = nohup_basename(command)
          pid = "#{sun.deploy_path :current}/tmp/pids/#{filename}.pid"
          <<-SH.squish
            sudo pkill '-P' "$(cat #{pid})" && rm -f #{pid} || rm -f #{pid}
          SH
        else
          <<-SH.squish
            #{rbenv_ruby} #{path} #{rbenv_sudo} #{context} #{command} |&
            tee -a #{sun.deploy_path :current, BASH_LOG}
          SH
        end
      end

      def nohup_basename(command)
        command.squish.gsub(/[^_\w]/, '-').gsub(/-{2,}/, '-').delete_prefix('-').delete_suffix('-')
      end
    end
  end
end
