module ExtCapistrano
  module Helpers
    RSYNC_ARCHIVE_OPTIONS = "--rsync-path='sudo rsync' --inplace --partial -azvh"

    def execute_cap(stage, task, environment = {})
      command = "bin/cap #{stage} #{task}"
      execute_ruby(command, environment.merge(rails_env: 'development', git_user: ENV['GIT_USER'], git_pass: ENV['GIT_PASS']))
    end

    def execute_rake(task, nohup: false, sudo: false, output: false)
      task = task.dup
      rake_sudo = sudo || ENV['RAKE_SUDO'].in?(['true', '1']) || task.sub!(/(^| +)RAKE_SUDO=(true|1)( +|$)/, ' ')
      skip_output = !output || ENV['RAKE_OUTPUT'].in?(['false', '0']) || task.sub!(/(^| +)RAKE_OUTPUT=(false|0)( +|$)/, ' ')
      command = "bin/rake #{task}"
      if nohup
        filename = nohup_basename(command)
        command = "#{command} >> log/#{filename}.log 2>&1 & sleep 1 && echo $! > tmp/pids/#{filename}.pid"
      end
      execute_ruby command, nohup: nohup, sudo: rake_sudo, rake_output: !skip_output
    end

    def execute_ruby(command, environment = {})
      environment = { rails_env: cap.env, rails_app: cap.app }.merge(environment)
      sudo = environment.delete(:sudo) || environment.delete('sudo')
      nohup = environment.delete(:nohup) || environment.delete('nohup')
      environment = environment.map do |name, value|
        %{#{name.is_a?(Symbol) ? name.to_s.upcase : name}="#{value.to_s.gsub(/"/, '\"')}"}
      end
      rbenv_ruby = "#{Sh.rbenv_export(fetch(:deployer_name))}; #{Sh.rbenv_init};"
      rbenv_sudo = "rbenv sudo #{environment.join(' ')}" if sudo
      context = environment.map{ |value| "export #{value};" }.join(' ') unless sudo
      path = " cd #{current_path};"
      if nohup
        execute <<-SH.squish, pty: false
          #{rbenv_ruby} #{context} #{path} nohup #{rbenv_sudo} #{command}
        SH
      else
        execute <<-SH.squish
          #{rbenv_ruby} #{path} #{rbenv_sudo} #{context} #{command}
        SH
      end
    end

    def execute_bash(inline_code, sudo: false, u: true)
      tmp_file = shared_path.join("tmp/files/cap_#{SecureRandom.hex(8)}.sh")
      upload! StringIO.new(inline_code), tmp_file
      execute "chmod +x #{tmp_file} && #{'sudo' if sudo} bash -#{'u' if u}c #{tmp_file} && rm -f #{tmp_file}"
    end

    def kill_nohup(command)
      filename = nohup_basename(command)
      execute :sudo, :pkill, '-P', "$(cat #{current_path}/tmp/pids/#{filename}.pid)"
    end

    def nohup_basename(command)
      command.squish.gsub(/[^_\w]/, '-').gsub(/-{2,}/, '-').delete_prefix('-').delete_suffix('-')
    end

    def template_push(name, destination)
      raise 'host destination must be specified' unless destination.present?
      upload_erb "config/deploy/templates/#{name}", destination
    end

    def template_compile(name)
      compile_erb "config/deploy/templates/#{name}"
    end

    def remote_file_exist?(full_path, sudo: false)
      cmd =
        if sudo
          %{if sudo test -e #{full_path}; then echo "true"; fi}
        else
          %{if [[ -e #{full_path} ]]; then echo "true"; fi}
        end
      capture(cmd).to_b
    end

    def send_files(server, root, folder, user: false)
      run_locally{ execute "rsync --progress -rutzvh #{"--chown=#{fetch(:deployer_name)}:#{fetch(:deployer_name)}" if user} -e 'ssh -p #{fetch(:port, 22)}' #{root}/#{folder} #{server.user}@#{server.hostname}:#{shared_path}/#{root}/" }
    end

    def get_files(server, root, folder)
      run_locally{ execute "rsync --progress -rutzvh -e 'ssh -p #{fetch(:port, 22)}' #{server.user}@#{server.hostname}:#{shared_path}/#{root}/#{folder} ./#{root}/" }
    end

    def upload_file(server, source, destination, user: false)
      run_locally{ execute "rsync #{RSYNC_ARCHIVE_OPTIONS} #{"--chown=#{fetch(:deployer_name)}:#{fetch(:deployer_name)}" if user} -e 'ssh -p #{fetch(:port, 22)}' '#{source}' #{fetch(:deployer_name)}@#{server.hostname}:#{destination}" }
    end

    def download_file(server, source, destination)
      run_locally{ execute "rsync #{RSYNC_ARCHIVE_OPTIONS} -e 'ssh -p #{fetch(:port, 22)}' #{fetch(:deployer_name)}@#{server.hostname}:#{source} '#{destination}'" }
    end

    def upload_erb(source, destination)
      upload_file(host, compile_erb(source), destination)
    end

    def compile_erb(source)
      Rake::DSL.compile(source, fetch(:gems), deployer: false)
    end

    def flag_on?(...)
      Rake::DSL.flag_on?(...)
    end

    def maintenance_message(...)
      Rake::DSL.maintenance_message(...)
    end
  end
end
