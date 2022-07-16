module Sunzistrano
  CONFIG_PATH = 'config/sunzistrano'
  CONFIG_YML = 'config/sunzistrano.yml'
  BASH_LOG = 'sunzistrano.log'
  BASH_DIR = 'sunzistrano'
  MANIFEST_LOG = 'sun_manifest.log'
  MANIFEST_DIR = 'sun_manifest'
  METADATA_DIR = 'sun_metadata'
  DEFAULTS_DIR = 'sun_defaults'

  class Cli < Thor
    include Thor::Actions

    attr_reader :sun

    def self.exit_on_failure?
      true
    end

    desc 'provision [stage] [role] [--recipe] [--new-host] [--reboot]', 'Provision'
    method_options recipe: :string, new_host: false, reboot: false
    def provision(stage, role = 'system')
      do_provision(stage, role, provision: true)
    end

    desc 'specialize [stage] [role] [--recipe] [--new-host]', 'Specialize provisioning'
    method_options recipe: :string, new_host: false
    def specialize(stage, role = 'system')
      do_provision(stage, role, specialize: true)
    end

    desc 'rollback [stage] [role] [--recipe]', 'Rollback recipe'
    method_options recipe: :required, specialize: false
    def rollback(stage, role = 'system')
      do_provision(stage, role, rollback: true)
    end

    desc 'compile [stage] [role] [--recipe] [--rollback] [--specialize] [--reboot]', 'Compile provisioning'
    method_options recipe: :string, rollback: false, specialize: false, reboot: false
    def compile(stage, role = 'system')
      do_compile(stage, role)
    end

    desc 'download [stage] [role] [--path] [--defaults]', 'Dowload the file meant to be used as .ref template'
    method_options path: :required, defaults: false
    def download(stage, role = 'system')
      do_download(stage, role)
    end

    desc 'reset_ssh [stage] [role]', 'Reset ssh known hosts'
    def reset_ssh(stage, role = 'system')
      do_reset_ssh(stage, role)
    end

    no_tasks do
      def self.source_root
        File.expand_path('../../', __FILE__)
      end

      def do_provision(stage, role, **custom_options)
        do_compile(stage, role, **custom_options)
        run_role_cmd
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
        ref = ref.join(CONFIG_PATH, "files/#{path.delete_prefix('/')}.ref")
        FileUtils.mkdir_p File.dirname(ref)
        if sun.defaults
          path = "/home/#{sun.owner_name}/#{Sunzistrano::DEFAULTS_DIR}/#{path.gsub(/\//, '~')}"
        end
        unless system download_cmd(path, ref)
          puts "Cannot transfer [#{path}] to [#{ref}]".red
        end
      end

      def do_reset_ssh(stage, role)
        load_config(stage, role)
        run_reset_known_hosts
      end

      def load_config(stage, role, **custom_options)
        @sun = Sunzistrano::Context.new(stage, role, **options.symbolize_keys, **custom_options)
      end

      def copy_files
        basenames = "#{CONFIG_PATH}/{files,helpers,recipes,roles}/**/*"
        dirnames = [basenames]
        sun.gems.each_value do |root|
          dirnames << root.expand_path.join(basenames).to_s
        end
        dirnames << Sunzistrano.root.join(basenames).to_s
        files = []
        dirnames.each do |dirname|
          files += Dir[dirname].select{ |f| copy? f, files }
        end
        files.each do |file|
          compile_file File.expand_path(file), bash_path(file)
        end
      end

      def build_role
        around = %i(before after).each_with_object({}) do |hook, memo|
          src = Sunzistrano.root.join(CONFIG_PATH, basename("role_#{hook}.sh")).expand_path
          dst = bash_path("role_#{hook}.sh")
          compile_file src, dst
          memo[hook] = File.binread(dst)
        end
        content = around[:before]
        content << "\n"
        sun.gems.each_value do |root|
          sun.list_helpers(root).each do |file|
            content << "source helpers/#{file}\n"
          end
        end
        content << File.binread(bash_path("roles/#{sun.role}.sh"))
        content << "\n"
        content << around[:after]
        create_file bash_path('role.sh'), content, force: true, verbose: sun.debug
      end

      def compile_file(src, dst)
        source_path, destination_path = src.to_s, dst.to_s
        template src, dst, force: true, verbose: sun.debug
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

      def run_role_cmd
        Parallel.each(sun.servers, in_threads: Float::INFINITY) do |server|
          run_role_cmd_for(server)
        end
        run_reset_known_hosts if sun.new_host
        FileUtils.rm_rf(bash_dir) unless sun.debug
      end

      def run_reset_known_hosts
        hosts = sun.servers.map{ |server| `getent hosts #{server}`.squish.split }.flatten.uniq
        if hosts.any?
          hosts.each do |host|
            until `ssh-keygen -f "$HOME/.ssh/known_hosts" -R #{host} 2>&1 >/dev/null`.start_with? "Host #{host} not found in"
              Thread.pass
            end
          end
        end
      end

      def run_role_cmd_for(server)
        Open3.popen3(role_cmd(server)) do |stdin, stdout, stderr|
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
          puts "[#{server}] #{Time.now}"
          t.join
        end
      end

      def role_cmd(server)
        no_strict_host_key_checking = "-o 'StrictHostKeyChecking no'" if sun.new_host
        <<~CMD.squish
          #{ssh_add_vagrant} cd #{bash_dir} && tar cz . |
          ssh #{"-p #{sun.port}" if sun.port} #{no_strict_host_key_checking} -o LogLevel=ERROR
          #{"-o ProxyCommand='ssh -W %h:%p #{sun.owner_name}@#{sun.server}'" if sun.server_cluster?}
          #{sun.owner_name}@#{server}
          '#{role_remote_cmd}'
        CMD
      end

      def role_remote_cmd
        cleanup = "rm -rf ~/#{Sunzistrano::BASH_DIR} &&" unless sun.debug
        <<~CMD.squish
          #{cleanup}
          mkdir -p ~/#{Sunzistrano::BASH_DIR} &&
          cd ~/#{Sunzistrano::BASH_DIR} &&
          tar xz &&
          #{'sudo' if sun.sudo} bash role.sh |& tee -a ~/#{Sunzistrano::BASH_LOG}
        CMD
      end

      def download_cmd(path, ref)
        <<~CMD.squish
          #{ssh_add_vagrant} rsync --rsync-path='sudo rsync' -azvh -e
          "ssh #{"-p #{sun.port}" if sun.port} -o LogLevel=ERROR"
          #{sun.owner_name}@#{sun.server}:#{path} #{ref}
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

      def copy?(file, others)
        File.file?(file) &&
          !file.match?(/\.keep$/) &&
          !file.match?(/\/roles\/(?!(#{sun.role}(_(before|after|ensure))?)\.sh)/) &&
          others.none?{ |f| file.end_with? basename(f) }
      end

      def bash_path(file)
        File.expand_path("#{bash_dir}/#{basename(file)}")
      end

      def bash_dir
        @bash_dir ||= ".#{BASH_DIR}/#{[sun.app, sun.env, sun.role].compact.join('-')}"
      end

      def basename(file)
        file.sub(/.*#{CONFIG_PATH}\//, '')
      end
    end
  end
end
