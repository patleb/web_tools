module ExtCapistrano
  module FileHelper
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

    def upload_erb(server, source, destination)
      upload_file(server, compile_erb(source), destination)
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
