module Sunzistrano
  TASK = '[TASK]'.freeze
  DONE = '[DONE]'.freeze
  FAIL = '[FAIL]'.freeze

  Cli.class_eval do
    desc 'rake [STAGE] [TASK] [--host] [--sudo] [--nohup] [--verbose] [--kill]', 'Execute a rake task'
    method_options host: :string, sudo: false, nohup: false, verbose: false, kill: false
    def rake(stage, task)
      do_rake(stage, task)
    end

    no_tasks do
      def do_rake(stage, task)
        with_context(stage, :deploy) do
          run_job_cmd :rake, task
        end
      end

      alias_method :run_role_cmd_without_local_tasks, :run_role_cmd
      def run_role_cmd
        (sun.local_tasks || []).reject(&:blank?).each do |task|
          started_at = Concurrent.monotonic_time
          context = "RAILS_ENV=#{sun.env} RAILS_APP=#{sun.app} BASH_DIR=#{sun.bash_dir}"
          command = "#{context} bin/rake #{task}"
          puts "[#{Time.now.utc}]#{TASK} #{task}".cyan
          output, status = capture2e(command)
          total = (Concurrent.monotonic_time - started_at).seconds.ceil(3)
          if status == 0
            puts output
            puts "[#{Time.now.utc}]#{DONE} #{task} -- : #{total} seconds".green
          else
            puts "[#{Time.now.utc}]#{FAIL} #{task} -- : #{total} seconds".red
            raise output
          end
        end
        run_role_cmd_without_local_tasks
      end

      def rake_remote_cmd(task)
        environment = ["RAKE_OUTPUT=#{sun.verbose.to_b}", "RAILS_ENV=#{sun.env}", "RAILS_APP=#{sun.app}"]
        if sun.sudo
          rbenv_sudo = "rbenv sudo #{environment.join(' ')}"
        else
          context = environment.map{ |value| "export #{value};" }.join(' ')
        end
        path = "cd #{sun.deploy_path :current};"
        command = "bin/rake #{task}"
        if sun.nohup
          filename = nohup_basename(command)
          command = "#{command} >> log/#{filename}.log 2>&1 & sleep 1 && echo $! > tmp/pids/#{filename}.pid"
          <<-SH.squish
            #{Sh.rbenv_ruby} #{path} #{context} nohup #{rbenv_sudo} #{command}
          SH
        elsif sun.kill
          filename = nohup_basename(command)
          pid = "#{sun.deploy_path :current}/tmp/pids/#{filename}.pid"
          <<-SH.squish
            sudo pkill '-P' "$(cat #{pid})" && rm -f #{pid} || rm -f #{pid}
          SH
        else
          <<-SH.squish
            #{Sh.rbenv_ruby} #{path} #{rbenv_sudo} #{context} #{command} |&
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
