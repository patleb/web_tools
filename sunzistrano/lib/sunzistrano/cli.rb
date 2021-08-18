# TODO https://github.com/christophemaximin/executable_mock
module Sunzistrano
  class Cli < Thor
    include Thor::Actions

    attr_reader :sun

    def self.exit_on_failure?
      true
    end

    desc 'provision [stage] [role] [--recipe] [--username]', 'Provision sunzistrano project'
    method_options recipe: :string, username: :string
    def provision(stage, role = 'system')
      do_provision(stage, role)
    end

    desc 'specialize [stage] [role] [--recipe] [--username]', 'Specialize sunzistrano project'
    method_options recipe: :string, username: :string
    def specialize(stage, role = 'system')
      do_provision(stage, role, specialize: true)
    end

    desc 'rollback [stage] [role] [--recipe] [--username]', 'Rollback sunzistrano recipe'
    method_options recipe: :required, specialize: false, username: :string
    def rollback(stage, role = 'system')
      do_provision(stage, role, rollback: true)
    end

    desc 'compile [stage] [role] [--recipe] [--rollback] [--specialize]', 'Compile sunzistrano project'
    method_options recipe: :string, rollback: false, specialize: false
    def compile(stage, role = 'system')
      do_compile(stage, role)
    end

    desc 'download [stage] [role] [--path] [--saved]', 'Dowload file meant to be used as .ref template'
    method_options path: :required, saved: false
    def download(stage, role = 'system')
      do_download(stage, role)
    end

    no_tasks do
      def self.source_root
        File.expand_path('../../', __FILE__)
      end

      def do_provision(stage, role, **custom_options)
        do_compile(stage, role, **custom_options)
        validate_version!
        run_provision_cmd
      end

      def do_compile(stage, role, **custom_options)
        load_config(stage, role, **custom_options)
        copy_files
        build_role
      end

      def do_download(stage, role)
        load_config(stage, role)
        path = sun.path
        ref = Pathname.new(Dir.pwd).expand_path
        ref = ref.join('config', 'provision', 'files', "#{path.delete_prefix('/')}.ref")
        FileUtils.mkdir_p File.dirname(ref)
        if sun.saved
          path = "/home/#{sun.username}/#{Sunzistrano::Context::DEFAULTS_DIR}/#{path.gsub(/\//, '~')}"
        end
        unless system download_cmd(path, ref)
          puts "Cannot transfer [#{path}] to [#{ref}]".red
        end
      end

      def load_config(stage, role, **custom_options)
        validate_config_presence!
        @sun = Sunzistrano::Context.new(stage, role, **options.symbolize_keys, **custom_options)
      end

      def copy_files
        basenames = "config/provision/{files,helpers,recipes,roles}/**/*"

        dirnames = [basenames]
        dirnames << sun.local_dir.join(basenames).to_s if sun.local_dir
        (sun.gems || []).each do |name|
          next unless (root = Gem.root(name))
          require "#{name}/sunzistrano" rescue nil
          dirnames << root.expand_path.join(basenames).to_s
        end
        dirnames << Sunzistrano.root.join(basenames).to_s

        files = []
        dirnames.each do |dirname|
          files += Dir[dirname].select{ |f| provision? f, files }
        end

        files.each do |file|
          compile_file File.expand_path(file), expand_path(:provision, file)
        end

        (sun.local_files || []).each do |file|
          compile_file File.expand_path(file), expand_path(:provision, "files/local/#{File.basename(file)}")
        end
      end

      def build_role
        around = %i(before after).each_with_object({}) do |hook, memo|
          path = expand_path(:provision, "role_#{hook}.sh")
          compile_file expand_path(:root, "role_#{hook}.sh"), path
          memo[hook] = File.binread(path)
        end
        content = around[:before]
        content << "\n"
        content << File.binread(expand_path(:provision, "roles/#{sun.role}.sh"))
        content << "\n"
        content << around[:after]
        create_file expand_path(:provision, "role.sh"), content, force: true
        compile_file expand_path(:root, "sun.sh"), expand_path(:provision, "sun.sh")
      end

      def compile_file(src, dst)
        source_path, destination_path = src.to_s, dst.to_s
        template src, dst, force: true
        if source_path.end_with? '.esh'
          ref_path = destination_path.sub(/\.esh$/, '.ref')
          if File.exist? ref_path
            esh_text, ref_file = Pathname.new(destination_path).read, Pathname.new(ref_path)
            ref_file.each_line do |line|
              if line.match? /[^\\][`$]/
                raise "unescaped ` or $ in '#{basename(src)}' file" if esh_text.include? line.strip
              end
            end
          end
        end
      end

      def validate_version!
        unless sun.lock.nil? || sun.lock == Sunzistrano::VERSION
          abort "Sunzistrano version [#{Sunzistrano::VERSION}] is different from locked version [#{sun.lock}]"
        end
      end

      def validate_config_presence!
        abort_with 'You must have a provision.yml'unless Sunzistrano::Context.provision_yml.exist?
      end

      def run_provision_cmd
        run_reset_known_hosts
        Parallel.each(sun.servers, in_threads: Float::INFINITY) do |server|
          run_provison_cmd_for(server)
        end
        FileUtils.rm_rf('.provision') unless sun.debug
      end

      def run_reset_known_hosts
        hosts = sun.servers.map{ |server| `getent hosts #{server}`.squish.split }.flatten.uniq
        if hosts.any?
          hosts.each do |host|
            `ssh-keygen -f "$HOME/.ssh/known_hosts" -R #{host} 2> /dev/null`
            while File.read("#{ENV['HOME']}/.ssh/known_hosts").include? host
              sleep 1
            end
          end
        end
      end

      def run_provison_cmd_for(server)
        Open3.popen3(provision_cmd(server)) do |stdin, stdout, stderr|
          stdin.close
          t = Thread.new do
            while (line = stderr.gets)
              print "[#{server}] "
              print line.red
            end
          end
          while (line = stdout.gets)
            print "[#{server}] "
            print line.green
          end
          t.join
        end
      end

      def provision_cmd(server)
        <<~CMD.squish
          #{ssh_add_vagrant} cd .provision && tar cz . |
          ssh #{"-p #{sun.port}" if sun.port} -o 'StrictHostKeyChecking no' -o LogLevel=ERROR
          #{"-o ProxyCommand='ssh -W %h:%p #{sun.username}@#{sun.server}'" if sun.server_cluster?}
          #{sun.username}@#{server}
          '#{provision_remote_cmd}'
        CMD
      end

      def provision_remote_cmd
        <<~CMD.squish
          rm -rf ~/#{Sunzistrano::Context::PROVISION_DIR} &&
          mkdir ~/#{Sunzistrano::Context::PROVISION_DIR} &&
          cd ~/#{Sunzistrano::Context::PROVISION_DIR} &&
          tar xz &&
          #{'sudo' if sun.sudo} bash role.sh |& tee -a ~/#{Sunzistrano::Context::PROVISION_LOG}
        CMD
      end

      def download_cmd(path, ref)
        <<~CMD.squish
          #{ssh_add_vagrant} rsync --rsync-path='sudo rsync' -azvh -e
          "ssh #{"-p #{sun.port}" if sun.port} -o 'StrictHostKeyChecking no' -o LogLevel=ERROR"
          #{sun.username}@#{sun.server}:#{path} #{ref}
        CMD
      end

      def ssh_add_vagrant
        <<~CMD.squish if sun.env.vagrant?
          if [ $(ps ax | grep [s]sh-agent | wc -l) -eq 0 ]; then
            eval $(ssh-agent);
          fi
          && ssh-add .vagrant/private_key 2> /dev/null &&
        CMD
      end

      def provision?(file, others)
        File.file?(file) &&
          !file[/\.keep$/] &&
          !file[/\/roles\/(?!(#{sun.role}|hook_\w+)\.sh)/] &&
          others.none?{ |f| file.end_with? basename(f) }
      end

      def expand_path(type, file = type)
        case type
        when :root
          file = Sunzistrano.root.join("config/provision/#{basename(file)}")
        when :provision
          file = ".provision/#{basename(file)}"
        else
          file = "config/provision/#{basename(file)}"
        end
        File.expand_path(file)
      end

      def basename(file)
        file.sub(/.*config\/provision\//, '')
      end

      def abort_with(text)
        puts text.red
        abort
      end
    end
  end
end
