module Sunzistrano
  CONFIG_PATH = 'config/sunzistrano'
  CONFIG_YML = 'config/sunzistrano.yml'
  BASH_DIR = '.sunzistrano'
  BASH_LOG = 'sun_bash.log'
  DEFAULTS_DIR = 'sun_defaults'
  MANIFEST_DIR = 'sun_manifest'
  MANIFEST_LOG = 'sun_manifest.log'
  METADATA_DIR = 'sun_metadata'

  def self.owner_path(dir, name = nil)
    base_dir = ['system', Setting.rails_env, Setting.rails_app].join('-')
    if name
      const_name = dir.to_s.upcase
      name = const_name.end_with?('_DIR') && const_defined?(const_name) ? "#{const_get(const_name)}/#{name}" : dir
    end
    "/home/#{Setting[:owner_name]}/#{base_dir}/#{name}"
  end

  class Cli < Thor
    include Thor::Actions

    attr_reader :sun

    def self.exit_on_failure?
      true
    end

    desc 'rake [stage] [--role="web"] [--sudo] [--nohup] [--verbose]', 'Execute a rake task'
    method_options role: 'web', sudo: false, nohup: false, verbose: false, task: :required
    def rake(stage)
      # TODO
    end

    desc 'deploy [stage] [--role="web"] [--system]', 'Deploy role'
    method_options role: 'web', system: false
    def deploy(stage)
      raise 'deploy role cannot be "system"' if options.role == 'system'
      do_provision(stage, deploy: true)
    end

    desc 'provision [stage] [--new-host] [--reboot] [--recipe]', 'Provision system'
    method_options new_host: false, reboot: false, recipe: :string
      def provision(stage)
      do_provision(stage, provision: true)
    end

    desc 'specialize [stage] [--new-host] [--recipe]', 'Specialize provisioning'
    method_options new_host: false, recipe: :string
      def specialize(stage)
      do_provision(stage, specialize: true)
    end

    desc 'rollback [stage] [--specialize]', 'Rollback provisioned recipe'
    method_options specialize: false, recipe: :required
      def rollback(stage)
      do_provision(stage, rollback: true)
    end

    desc 'compile [stage] [--role="system"] [--specialize] [--rollback] [--reboot] [--recipe]', 'Compile provisioning'
    method_options role: 'system', specialize: false, rollback: false, reboot: false, recipe: :string
    def compile(stage)
      command_options = options.role == 'system' ? { provision: true } : { deploy: true, revision: true }
      do_compile(stage, **command_options)
    end

    desc 'download [stage] [--defaults]', 'Dowload the file meant to be used as .ref template'
    method_options defaults: false, path: :required
      def download(stage)
      do_download(stage)
    end

    desc 'reset_ssh [stage]', 'Reset ssh known hosts'
    def reset_ssh(stage)
      do_reset_ssh(stage)
    end

    no_tasks do
      def self.source_root
        File.expand_path('../../', __FILE__)
      end

      def do_provision(stage, **command_options)
        do_compile(stage, **command_options)
        run_role_cmd
      end

      def do_compile(stage, **command_options)
        with_context(stage, **command_options) do
          copy_files
          build_role
        end
      end

      def do_download(stage)
        with_context(stage) do
          path = sun.path
          ref = Setting.rails_root.join(CONFIG_PATH, "files/#{path.delete_prefix('/')}.ref")
          FileUtils.mkdir_p File.dirname(ref)
          if sun.defaults
            path = Sunzistrano.owner_path :defaults_dir, path.tr('/', '~')
          end
          unless system download_cmd(path, ref)
            raise "Cannot transfer [#{path}] to [#{ref}]"
          end
        end
      end

      def do_reset_ssh(stage)
        with_context(stage) do
          run_reset_known_hosts
        end
      end

      def with_context(stage, **command_options)
        env, app = stage.split(':', 2)
        Setting.with(env: env, app: app) do
          @sun = Sunzistrano::Context.new(**options.symbolize_keys, **command_options)
          yield
        end
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
          sun.helpers(root).each do |file|
            content << "source helpers/#{file}\n"
          end
        end
        content << File.binread(bash_path("roles/#{sun.role}.sh"))
        content << "\n"
        content << around[:after]
        create_file bash_path('role.sh'), content, force: true, verbose: sun.debug
        %i(before after ensure).each do |hook|
          next unless (files = sun["role_#{hook}"]).present?
          content = files.map{ |file| "source roles/#{file}.sh" }.join("\n")
          create_file bash_path("roles/#{sun.role}_#{hook}.sh"), content, force: true, verbose: sun.debug
        end
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
            print line
          end
          print "[#{server}] "
          puts Time.now.to_s.yellow
          t.join
        end
      end

      def role_cmd(server)
        no_strict_host_key_checking = "-o 'StrictHostKeyChecking no'" if sun.new_host
        <<~CMD.squish
          #{ssh_add_vagrant} cd #{bash_dir} && tar cz . |
          ssh #{"-p #{sun.ssh_port}" if sun.ssh_port} #{no_strict_host_key_checking} -o LogLevel=ERROR
          #{"-o ProxyCommand='ssh -W %h:%p #{sun.ssh_user}@#{sun.server_host}'" if sun.server_cluster?}
          #{sun.ssh_user}@#{server}
          '#{role_remote_cmd}'
        CMD
      end

      def role_remote_cmd
        cleanup = "rm -rf #{bash_dir_remote} &&" unless sun.debug
        <<~CMD.squish
          #{cleanup}
          mkdir -p #{bash_dir_remote} &&
          cd #{bash_dir_remote} &&
          tar xz &&
          #{'sudo' if sun.sudo} bash role.sh |& tee -a #{bash_log_remote}
        CMD
      end

      def download_cmd(path, ref)
        <<~CMD.squish
          #{ssh_add_vagrant} rsync --rsync-path='sudo rsync' -azvh -e
          "ssh #{"-p #{sun.ssh_port}" if sun.ssh_port} -o LogLevel=ERROR"
          #{sun.ssh_user}@#{sun.server_host}:#{path} #{ref}
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
          !file.match?(/\/roles\/(?!((#{sun.role}|shared)(\/.+)?)\.sh)/) &&
          others.none?{ |f| file.end_with? basename(f) }
      end

      def bash_path(file)
        File.expand_path("#{bash_dir}/#{basename(file)}")
      end

      def bash_dir
        @bash_dir ||= "#{BASH_DIR}/#{sun.provision_dir}"
      end

      def bash_dir_remote
        sun.provision_path BASH_DIR
      end

      def bash_log_remote
        sun.provision_path BASH_LOG
      end

      def basename(file)
        file.sub(/.*#{CONFIG_PATH}\//, '')
      end
    end
  end
end
