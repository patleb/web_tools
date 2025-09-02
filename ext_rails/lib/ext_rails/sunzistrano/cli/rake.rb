module Sunzistrano
  TASK = '[TASK]'
  DONE = '[DONE]'
  FAIL = '[FAIL]'
  WAIT_DURATION = /^(\d+\.(second|minute|hour|day|week)s?)(\s*\+\s*\d+\.(second|minute|hour|day|week)s?)*$/

  Cli.class_eval do
    desc 'rake [STAGE] [TASK] [--host] [--no-proxy] [--sudo] [--nohup] [--wait] [--verbose] [--term] [--kill]', 'Execute a rake task'
    method_options host: :string, proxy: true, sudo: false, nohup: false, wait: :string, verbose: false, term: false, kill: false
    def rake(stage, task) = do_rake(stage, task)

    no_tasks do
      def do_rake(stage, task)
        with_context(stage, :deploy) do
          run_job_cmd :rake, task
        end
      end

      def rake_remote_cmd(task)
        rake_output = sun.verbose || sun.nohup || sun.wait.present? || ENV['RAKE_OUTPUT'].to_b
        environment = ["PACK=#{pack? task}", "RAKE_OUTPUT=#{rake_output}", "RAILS_ENV=#{sun.env}", "RAILS_APP=#{sun.app}"]
        if sun.sudo
          rbenv_sudo = "rbenv sudo #{environment.join(' ')}"
        else
          context = environment.map{ |value| "export #{value};" }.join(' ')
        end
        path = "cd #{sun.deploy_path :current};"
        command = "bin/rake #{task}"
        if sun.wait.present?
          minutes, seconds = parse_wait
          raise "invalid wait '#{sun.wait}'" unless minutes
          sleep = "sleep #{seconds};" if seconds > 0
          <<-SH.squish
            echo -e '#{sleep} #{Sh.rbenv_ruby} #{path} #{rbenv_sudo} #{context} #{rake_with_log command}' |
            at now + #{minutes} minutes
          SH
        elsif sun.nohup
          <<-SH.squish
            #{Sh.rbenv_ruby} #{path} #{context} nohup #{rbenv_sudo} #{rake_with_log command}
          SH
        elsif sun.term || sun.kill
          pid = "#{sun.deploy_path :current}/tmp/pids/#{rake_log_basename(command)}.pid"
          <<-SH.squish
            ppid=$(cat #{pid});
            sudo pkill #{'-9' if sun.kill} --parent $ppid &&
            rm -f #{pid} && echo "killed [$ppid] child processes" ||
            rm -f #{pid} && echo "could not kill [$ppid] child processes"
          SH
        else
          <<-SH.squish
            #{Sh.rbenv_ruby} #{path} #{rbenv_sudo} #{context} #{command} 2>&1 |
            tee -a #{sun.deploy_path :current, BASH_LOG}
          SH
        end
      end

      def rake_with_log(command)
        name = rake_log_basename(command)
        "#{command} >> log/#{name}.log 2>&1 & sleep 1 && echo $! > tmp/pids/#{name}.pid"
      end

      def rake_log_basename(command)
        command.squish.gsub(/[^_\w]/, '-').gsub(/-{2,}/, '-').delete_prefix('-').delete_suffix('-')
      end

      def parse_wait
        wait_at = if sun.wait.match? WAIT_DURATION
          sun.wait.split(/\s*\+\s*/).map(&:split.with('.')).sum{ |(n, unit)| n.to_i.send(unit) }.from_now
        else
          Time.parse_utc(sun.wait) rescue return
        end
        wait = (wait_at - Time.current).to_i
        wait = 60 if wait < 60
        [wait / 60, wait % 60]
      end

      def pack?(task)
        task.start_with? 'assets:', 'shakapacker:'
      end
    end
  end
end
