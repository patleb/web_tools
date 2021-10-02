module ExtCapistrano
  module Helpers
    RSYNC_OPTIONS = "--rsync-path='sudo rsync' --inplace --partial -azvh"

    def execute_cap(stage, task, environment = {})
      with_ruby(environment.merge(rails_env: 'development', git_user: ENV['GIT_USER'], git_pass: ENV['GIT_PASS'])) do |context|
        execute <<-SH.squish
          #{context}
          bin/cap #{stage} #{task}
        SH
      end
    end

    def execute_rake(task, environment = {})
      with_ruby(environment.merge(rake_output: true)) do |context|
        execute <<-SH.squish
          #{context}
          bin/rake #{task}
        SH
      end
    end

    def execute_nohup(command)
      with_ruby(rake_output: true) do |context|
        filename = nohup_basename(command)
        execute <<-SH.squish, pty: false
          #{context}
          nohup #{command} >> log/#{filename}.log 2>&1 & sleep 1 && echo $! > tmp/pids/#{filename}.pid
        SH
      end
    end

    def kill_nohup(command)
      filename = nohup_basename(command)
      execute :sudo, :pkill, '-P', "$(cat #{current_path}/tmp/pids/#{filename}.pid)"
    end

    def nohup_basename(command)
      command.squish.gsub(/[^_\w]/, '-').gsub(/-{2,}/, '-').delete_prefix('-').delete_suffix('-')
    end

    def with_ruby(environment = {})
      environment = { rails_env: cap.env, rails_app: cap.app }.merge(environment).map do |k, v|
        %{export #{k.is_a?(Symbol) ? k.to_s.upcase : k}="#{v.to_s.gsub(/"/, '\"')}";}
      end.join(' ')
      yield "#{Sh.rbenv_export(fetch(:deployer_name))}; #{Sh.rbenv_init}; #{environment} cd #{current_path};"
    end

    def execute_bash(inline_code, sudo: false, u: true)
      tmp_file = shared_path.join("tmp/files/cap_#{SecureRandom.hex(8)}.sh")
      upload! StringIO.new(inline_code), tmp_file
      execute "chmod +x #{tmp_file} && #{'sudo' if sudo} bash -#{'u' if u}c #{tmp_file} && rm -f #{tmp_file}"
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

    def upload_file(server, source, destination, user: false)
      run_locally{ execute "rsync #{RSYNC_OPTIONS} #{"--chown=#{fetch(:deployer_name)}:#{fetch(:deployer_name)}" if user} -e 'ssh -p #{fetch(:port, 22)}' '#{source}' #{fetch(:deployer_name)}@#{server.hostname}:#{destination}" }
    end

    def download_file(server, source, destination)
      run_locally{ execute "rsync #{RSYNC_OPTIONS} -e 'ssh -p #{fetch(:port, 22)}' #{fetch(:deployer_name)}@#{server.hostname}:#{source} '#{destination}'" }
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
  end
end
