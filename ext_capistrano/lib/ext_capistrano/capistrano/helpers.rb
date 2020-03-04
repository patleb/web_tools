module ExtCapistrano
  module Helpers
    def execute_cap(stage, task, environment = {})
      with_cap environment do
        execute :cap, stage, task
      end
    end

    def with_cap(environment = {})
      environment = environment.merge(rails_env: 'development', git_user: ENV['GIT_USER'], git_pass: ENV['GIT_PASS'])
      within current_path do
        with environment do
          yield
        end
      end
    end

    def execute_rake(task, environment = {})
      with_rake environment do
        execute :rake, task
      end
    end

    def with_rake(environment = {})
      environment = environment.merge(rails_env: cap.env, rails_app: cap.app, rake_output: true)
      within current_path do
        with environment do
          yield
        end
      end
    end

    def execute_nohup(command)
      filename = nohup_basename(command)
      execute :nohup, "#{command} >> log/#{filename}.log 2>&1 & sleep 1 && echo $! > tmp/pids/#{filename}.pid", pty: false
    end

    def kill_nohup(command)
      filename = nohup_basename(command)
      execute :sudo, :pkill, '-P', "$(cat #{current_path}/tmp/pids/#{filename}.pid)"
    end

    def nohup_basename(command)
      command.squish.gsub(/[^_\w]/, '-').gsub(/-{2,}/, '-').delete_prefix('-').delete_suffix('-')
    end

    def execute_bash(inline_code, sudo: false, u: true)
      tmp_file = shared_path.join('tmp', 'bash', "tmp.#{SecureRandom.hex(8)}.sh")
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

    def send_files(server, root, folder)
      run_locally{ execute "rsync --progress -rutzvh -e 'ssh -p #{fetch(:port, 22)}' #{root}/#{folder} #{server.user}@#{server.hostname}:#{shared_path}/#{root}/" }
    end

    def get_files(server, root, folder)
      run_locally{ execute "rsync --progress -rutzvh -e 'ssh -p #{fetch(:port, 22)}' #{server.user}@#{server.hostname}:#{shared_path}/#{root}/#{folder} ./#{root}/" }
    end

    def upload_file(server, source, destination, user: false)
      run_locally{ execute "rsync --rsync-path='sudo rsync' #{"--chown=#{fetch(:deployer_name)}:#{fetch(:deployer_name)}" if user} -azvh -e 'ssh -p #{fetch(:port, 22)}' '#{source}' #{fetch(:deployer_name)}@#{server.hostname}:#{destination}" }
    end

    def download_file(server, source, destination)
      run_locally{ execute "rsync --rsync-path='sudo rsync' -azvh -e 'ssh -p #{fetch(:port, 22)}' #{fetch(:deployer_name)}@#{server.hostname}:#{source} '#{destination}'" }
    end

    def upload_erb(source, destination)
      upload_file(host, compile_erb(source), destination)
    end

    def compile_erb(source)
      base_dir = Pathname.new("tmp/#{File.dirname(source)}")
      new_file = base_dir.join(File.basename(source))
      FileUtils.mkdir_p base_dir
      File.open(new_file, 'w') do |f|
        source_erb = "#{source}.erb"

        unless File.exist? source_erb
          fetch(:gems).each do |name|
            if (root = Gem.root(name))
              if (path = root.join(source_erb)).exist?
                source_erb = path
                break
              end
            end
          end
        end

        f.puts ERB.new(File.read(source_erb), nil, '-').result
      end
      new_file
    end
  end
end
