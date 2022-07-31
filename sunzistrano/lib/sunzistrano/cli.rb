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
    if name
      const_name = dir.to_s.upcase
      name = const_name.end_with?('_DIR') && const_defined?(const_name) ? "#{const_get(const_name)}/#{name}" : dir
    end
    "/home/#{Setting[:owner_name]}/#{Setting.rails_stage}/#{name}"
  end

  class Cli < Thor
    include Thor::Actions

    attr_reader :sun

    def self.exit_on_failure?
      true
    end

    desc 'rake [stage] [task] [--sudo] [--nohup]', 'Execute a rake task'
    method_options sudo: false, nohup: false
    def rake(stage, task)
      # TODO verbose if nohup (RAKE_OUTPUT=true)
    end

    desc 'bash [stage] [script] [--sudo] [--nohup]', 'Execute a bash script'
    method_options sudo: false, nohup: false
    def bash(stage, script)
      do_bash(stage, script)
    end

    desc 'deploy [stage] [--system]', 'Deploy application'
    method_options system: false
    def deploy(stage)
      do_provision(stage, :deploy)
    end

    desc 'provision [stage] [--specialize] [--rollback] [--recipe] [--reboot] [--new-host]', 'Provision system'
    method_options specialize: false, rollback: false, recipe: :string, reboot: false, new_host: false
    def provision(stage)
      raise '--recipe is required for rollback' if options.rollback && options.recipe.blank?
      do_provision(stage, :provision)
    end

    desc 'compile [stage] [--deploy] [--system] [--specialize] [--rollback] [--recipe] [--reboot]', 'Compile provisioning'
    method_options deploy: false, system: false, specialize: false, rollback: false, recipe: :string, reboot: false
    def compile(stage)
      do_compile(stage, options.deploy ? :deploy : :provision)
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

      def do_bash(stage, script)
        with_context(stage, :deploy, script: script) do
          run_script_cmd
        end
      end

      def do_provision(stage, role, **command_options)
        do_compile(stage, role, **command_options)
        run_role_cmd
      end

      def do_compile(stage, role, **command_options)
        with_context(stage, role, **command_options) do
          copy_files
          build_helpers
          build_role
          build_scripts
        end
      end

      def do_download(stage)
        with_context(stage) do
          path = sun.path
          ref = Setting.rails_root.join(CONFIG_PATH, "files/#{path.delete_prefix('/')}.ref")
          FileUtils.mkdir_p File.dirname(ref)
          path = Sunzistrano.owner_path :defaults_dir, path.tr('/', '~') if sun.defaults
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

      def with_context(stage, role = nil, **command_options)
        env, app = stage.split('-', 2)
        Setting.with(env: env, app: app) do
          @sun = Sunzistrano::Context.new(role, **options.symbolize_keys, **command_options)
          yield
        end
      end

      def build_scripts
        copy_hooks :script
        script = {
          before: "source script_before.sh\n",
          after: "source script_after.sh\n",
        }
        used = Set.new
        (sun.scripts || []).each do |file|
          used << (dst = bash_path("scripts/#{file}.sh"))
          script[:code] = File.binread(dst)
          content = script.values_at(:before, :code, :after).join("\n")
          create_file dst, content, force: true, verbose: sun.debug
        end
        remove_all_unused :script, used
      end

      def build_role
        copy_hooks :role
        role = {
          before: "source role_before.sh\n",
          recipes: File.binread(bash_path("roles/#{sun.role}.sh")).strip_heredoc,
          after: "source role_after.sh\n"
        }
        used = Set.new
        role[:recipes].each_line(chomp: true) do |line|
          next unless (recipe = line.match(/^ *sun\.source_recipe\s*["'\s]([^"'\s]+)/)&.captures&.first)
          file = bash_path("recipes/#{recipe}")
          used << "#{file}.sh"
          used << "#{file}-specialize.sh"
          used << "#{file}-rollback.sh"
        end
        content = role.values_at(:before, :recipes, :after).join("\n")
        create_file bash_path('role.sh'), content, force: true, verbose: sun.debug
        remove_all_unused :recipe, used
        %i(before after ensure).each do |hook|
          next unless (files = sun["role_#{hook}"]).present?
          content = files.map{ |file| "source roles/#{file}.sh" }.join("\n")
          create_file bash_path("roles/#{sun.role}_#{hook}.sh"), content, force: true, verbose: sun.debug
        end
      end

      def remove_all_unused(type, used)
        Dir[bash_path("#{type}s/**/*.sh")].each do |file|
          remove_file file, verbose: false unless used.include? file
        end
        Dir[bash_path("#{type}s/**/*")].select{ |dir| File.directory? dir }.reverse_each do |dir|
          next unless (Dir.entries(dir) - %w(. ..)).empty?
          Dir.rmdir(dir)
        end
      end

      def build_helpers
        src = Sunzistrano.root.join(CONFIG_PATH, 'helpers.sh').expand_path
        dst = bash_path('helpers.sh')
        template src, dst, force: true, verbose: sun.debug
      end

      def copy_files
        basenames = "#{CONFIG_PATH}/{files,helpers,recipes,roles,scripts}/**/*"
        dirnames = [basenames]
        sun.gems.each_value do |root|
          dirnames << root.expand_path.join(basenames).to_s
        end
        files = []
        dirnames.each do |dirname|
          files += Dir[dirname].select{ |f| copy? f, files }
        end
        files.each do |file|
          compile_file File.expand_path(file), bash_path(file), basetype(file)
        end
      end

      def compile_file(src, dst, type)
        dst = dst.delete_suffix('.erb') if src.end_with? '.erb'
        dst = sun.gsub_variables(dst) || dst if type == :file
        template src, dst, force: true, verbose: sun.debug
        if src.end_with? '.esh'
          ref_path = dst.sub(/\.esh$/, '.ref')
          if File.exist? ref_path
            esh_text, ref_file = Pathname.new(dst).read, Pathname.new(ref_path)
            ref_file.each_line do |line|
              if line.match? /[^\\][`$]/
                raise "unescaped ` or $ in '#{basename(src)}' file" if esh_text.include? line.strip
              end
            end
          end
        end
      end

      def copy_hooks(type)
        %i(before after).each do |hook|
          file = "#{type}_#{hook}.sh"
          src = Sunzistrano.root.join(CONFIG_PATH, basename(file)).expand_path
          dst = bash_path(file)
          copy_file src, dst, force: true, verbose: sun.debug
        end
      end

      def run_script_cmd
        Parallel.each(sun.servers, in_threads: Float::INFINITY) do |server|
          run_command :script_cmd, server
        end
      end

      def run_role_cmd
        Parallel.each(sun.servers, in_threads: Float::INFINITY) do |server|
          run_command :role_cmd, server
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

      def run_command(cmd_name, server)
        Open3.popen3(send(cmd_name, server)) do |stdin, stdout, stderr|
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
        <<~CMD.squish
          rm -rf #{bash_dir_remote} &&
          mkdir -p #{bash_dir_remote} &&
          cd #{bash_dir_remote} &&
          tar xz &&
          #{'sudo' if sun.sudo} bash -e -u role.sh |&
          tee -a #{bash_log_remote}
        CMD
      end

      def script_cmd(server)
        <<~CMD.squish
          #{ssh_add_vagrant}
          ssh #{"-p #{sun.ssh_port}" if sun.ssh_port} -o LogLevel=ERROR
          #{"-o ProxyCommand='ssh -W %h:%p #{sun.ssh_user}@#{sun.server_host}'" if sun.server_cluster?}
          #{sun.ssh_user}@#{server}
          '#{script_remote_cmd}'
        CMD
      end

      def script_remote_cmd
        <<~CMD.squish
          cd #{bash_dir_remote} &&
          #{'sudo' if sun.sudo} bash -e -u scripts/#{sun.script.gsub(/(^scripts\/|\.sh$)/, '')}.sh |&
          tee -a #{bash_log_remote}
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

      def basetype(file)
        basename(file).split('/').first.delete_suffix('s').to_sym
      end

      def basename(file)
        file.sub(/.*#{CONFIG_PATH}\//, '')
      end
    end
  end
end
