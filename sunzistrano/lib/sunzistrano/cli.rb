require 'sunzistrano/context'

module Sunzistrano
  CONFIG_PATH = 'config/sunzistrano'
  CONFIG_YML = 'config/sunzistrano.yml'
  BASH_DIR = '.sunzistrano'
  BASH_LOG = 'sun_bash.log'
  DEFAULTS_DIR = 'sun_defaults'
  MANIFEST_DIR = 'sun_manifest'
  MANIFEST_LOG = 'sun_manifest.log'
  METADATA_DIR = 'sun_metadata'

  def self.owner_path(dir, name)
    "/home/#{Setting[:owner_name]}/#{Setting.env}/#{const_get(dir.to_s.upcase)}/#{name}"
  end

  class Cli < Thor
    include Thor::Actions

    def self.source_root
      Sunzistrano.root.join('lib').to_s
    end

    def self.exit_on_failure?
      true
    end

    attr_reader :sun

    desc 'deploy [STAGE] [--system] [--rollback] [--recipe] [--force] [--no-sync] [--reset-ssh]', 'Deploy application'
    method_options system: false, rollback: false, recipe: :string, force: false, sync: true, reset_ssh: false
    def deploy(stage) = do_provision(stage, :deploy)

    desc 'provision [STAGE] [--specialize] [--rollback] [--recipe] [--force] [--reboot] [--reset-ssh]', 'Provision system'
    method_options specialize: false, rollback: false, recipe: :string, force: false, reboot: false, reset_ssh: false
    def provision(stage) = do_provision(stage, :provision)

    desc 'compile [STAGE] [--deploy] [--system] [--specialize] [--rollback] [--recipe] [--reboot]', 'Compile provisioning'
    method_options deploy: false, system: false, specialize: false, rollback: false, recipe: :string, reboot: false
    def compile(stage) = do_compile(stage)

    desc 'reset_ssh [STAGE] [--agent]', 'Reset ssh known hosts or agent'
    method_options agent: false
    def reset_ssh(stage) = do_reset_ssh(stage)

    no_tasks do
      delegate :owner_path, to: :Sunzistrano

      def do_provision(stage, role)
        raise '--recipe is required for rollback' if options.rollback && options.recipe.blank?
        do_compile(stage, role)
        run_role_cmd
      end

      def do_compile(stage, role = nil)
        with_context(stage, role) do
          raise 'local and remote commits differ' if out_of_sync?
          compile_all
        end
      end

      def do_reset_ssh(stage)
        with_context(stage) do
          if sun.agent
            system! 'killall ssh-agent; eval "$(ssh-agent)"'
          else
            run_reset_known_hosts
          end
        end
      end

      def with_context(stage, role = nil)
        env, app = stage.split('_', 2)
        role ||= options.deploy ? :deploy : :provision
        Setting.with(env: env, app: app) do
          @sun = Sunzistrano::Context.new(role, **options.symbolize_keys)
          yield
        end
      end

      def out_of_sync?
        sun.deploy && sun.sync && sun.revision != `git rev-parse HEAD`.strip
      end

      def compile_all
        copy_files
        copy_local_files
        build_helpers
        build_role
      end

      def copy_files
        paths = "#{CONFIG_PATH}/{files,helpers,recipes,roles,scripts}/**/*"
        dirs = [paths]
        sun.gems.each_value do |root|
          dirs << root.expand_path.join(paths).to_s
        end
        files = []
        dirs.each do |path|
          files += Dir[path].select{ |f| copy? f, files }
        end
        files.each do |file|
          compile_file File.expand_path(file), bash_path(file), basetype(file)
        end
      end

      def copy_local_files
        files = []
        (sun.files || []).each do |path|
          files += Dir[path].select_map do |f|
            file = Setting.root.join(f).to_s
            file if copy? file, files
          end
        end
        files.each do |file|
          compile_file file, bash_path(file)
        end
      end

      def compile_file(src, dst, type = nil)
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

      def build_helpers
        src = Sunzistrano.root.join(CONFIG_PATH, 'helpers.sh').expand_path
        dst = bash_path('helpers.sh')
        template src, dst, force: true, verbose: sun.debug
      end

      def build_role
        copy_hooks :role
        used = Set.new
        File.foreach(bash_path("roles/#{sun.role}.sh")) do |line|
          next unless (recipe = line.match(/^ *sun\.source_recipe\s*["'\s]([^"'\s]+)/)&.captures&.first)
          file = bash_path("recipes/#{recipe}")
          used << "#{file}.sh"
          used << "#{file}-specialize.sh"
          used << "#{file}-rollback.sh"
        end
        create_file bash_path('role.sh'), <<~SH, force: true, verbose: sun.debug
          source role_before.sh
          source roles/#{sun.role}.sh
          source role_after.sh
        SH
        remove_all_unused :recipe, used
        %i(before after ensure).each do |hook|
          next unless (files = sun["role_#{hook}"]).present?
          content = files.map{ |file| "source roles/#{file}.sh" }.join("\n")
          create_file bash_path("roles/#{sun.role}_#{hook}.sh"), content, force: true, verbose: sun.debug
        end
      end

      def copy_hooks(type)
        %i(before after).each do |hook|
          file = "#{type}_#{hook}.sh"
          src = Sunzistrano.root.join(CONFIG_PATH, basepath(file)).expand_path
          dst = bash_path(file)
          copy_file src, dst, force: true, verbose: sun.debug
        end
      end

      def remove_all_unused(type, used)
        Dir[bash_path("#{type}s/**/*.sh")].each do |file|
          next if file.end_with? '/recipes/reboot.sh'
          remove_file file, verbose: false unless used.include? file
        end
        Dir[bash_path("#{type}s/**/*")].select{ |dir| File.directory? dir }.reverse_each do |dir|
          next unless (Dir.entries(dir) - %w(. ..)).empty?
          FileUtils.rmdir(dir)
        end
      end

      def before_role
      end

      def after_role
      end

      def run_role_cmd
        run_reset_known_hosts if sun.reset_ssh
        run_update_cluster_ips_cmd
        before_role
        Parallel.each(sun.servers, in_threads: Float::INFINITY) do |server|
          run_command :role_cmd, server
        end
        after_role
        run_reset_known_hosts if sun.reset_ssh
        unless sun.debug
          FileUtils.rm_rf(bash_dir)
          FileUtils.rmdir(File.dirname(bash_dir)) rescue nil if sun.deploy
        end
      end

      def run_job_cmd(type, *args)
        raise 'run_job_cmd type cannot be "role"' if type.to_sym == :role
        status = Parallel.map(Array.wrap(options.host.presence || sun.servers), in_threads: Float::INFINITY) do |server|
          run_command :job_cmd, server, type, *args
        end
        unless status.all?
          exit false
        end
      end

      def job_cmd(server, type, *args)
        command = send "#{type}_remote_cmd", *args
        remote_cmd server, command.escape_single_quotes(:shell)
      end

      def run_update_cluster_ips_cmd
        return true unless sun.cloud_cluster
        unless run_command :update_cluster_ips_cmd, sun.server_host
          exit false
        end
      end

      def update_cluster_ips_cmd(server)
        path = "/home/#{sun.ssh_user}/#{sun.env}_#{Setting[:cloud_cluster_name]}"
        remote_cmd server, "echo '#{Cloud.cluster_ips.join(',')}' > #{path}", proxy: false
      end

      def run_reset_known_hosts
        return if Setting.local?
        hosts = sun.servers.map{ |server| `getent hosts #{server}`.squish.split }.flatten.uniq
        if hosts.any?
          hosts.each do |host|
            until `ssh-keygen -f "$HOME/.ssh/known_hosts" -R #{host} 2>&1 >/dev/null`.start_with? "Host #{host} not found in"
              Thread.pass
            end
          end
        end
      end

      def run_command(cmd_name, server, *args)
        status = true
        popen3(cmd_name, server, *args) do |stdin, stdout, stderr|
          stdin.close
          error = Thread.new do
            while (line = stderr.gets)
              if cmd_name == :role_cmd && line.start_with?('flock: failed')
                print "[#{server}] Already running -- : #{line.red}"
              else
                print "[#{server}] #{line.red}"
              end
              status = false
            end
          end
          while (line = stdout.gets)
            if cmd_name == :role_cmd && line.start_with?('flock:')
              print "[#{server}] Already running -- : #{line.red}" if line.start_with? 'flock: failed'
            else
              print "[#{server}] #{line}"
            end
          end
          puts "[#{server}] #{Time.current.to_s.yellow}" unless options.verbose == false
          error.join
        end
        status
      end

      def role_cmd(server)
        no_strict_host_key_checking = "-o 'StrictHostKeyChecking no'" if sun.reset_ssh
        <<-SH.squish
          #{ssh_virtual_key}
          cd #{bash_dir} && tar cz . |
          #{ssh_cmd} #{no_strict_host_key_checking} #{ssh_proxy} #{sun.ssh_user}@#{server} '#{role_remote_cmd}'
        SH
      end

      def role_remote_cmd
        <<-SH.squish
          mkdir -p #{bash_dir_remote} && cd #{bash_dir_remote} && start=$(mktemp) &&
          flock --verbose -n #{sun.deploy_path 'role.lock'} tar xz &&
          flock --verbose -n #{sun.deploy_path 'role.lock'} #{'sudo' if sun.sudo} bash -e -u +H role.sh 2>&1 |
          tee -a #{sun.provision_path BASH_LOG} && cd #{bash_dir_remote} &&
          find . -depth ! -cnewer $start -print0 | sponge /dev/stdout | xargs -r0 rm -d > /dev/null 2>&1 && rm -f $start
        SH
      end

      def remote_cmd(server, command, proxy: sun.cloud_cluster)
        <<-SH.squish
          #{ssh_virtual_key}
          #{ssh_cmd} #{ssh_proxy if proxy} #{sun.ssh_user}@#{server} '#{command}'
        SH
      end

      def ssh_cmd
        "ssh #{"-p #{sun.ssh_port}" if sun.ssh_port} -o LogLevel=ERROR"
      end

      def ssh_proxy
        "-o ProxyCommand='ssh -W %h:%p #{sun.ssh_user}@#{sun.server_host}'" if sun.cloud_cluster
      end

      def ssh_virtual_key
        <<-SH.squish if sun.env.virtual?
          if [ $(ps ax | grep [s]sh-agent | wc -l) -eq 0 ]; then
            eval $(ssh-agent);
          fi
          && ssh-add #{MULTIPASS_KEY} 2> /dev/null &&
        SH
      end

      def copy?(file, others)
        File.file?(file) &&
          !file.match?(/\.keep$/) &&
          !file.match?(/\/roles\/(?!((#{sun.role}|shared)(\/.+)?)\.sh)/) &&
          others.none?{ |f| file.end_with? basepath(f) }
      end

      def bash_path(file)
        File.expand_path("#{bash_dir}/#{basepath(file)}")
      end

      def bash_dir
        @bash_dir ||= [BASH_DIR, sun.revision, sun.stage].compact.join('/')
      end

      def bash_dir_remote
        sun.provision_path BASH_DIR
      end

      def basetype(file)
        basepath(file).split('/').first.delete_suffix('s').to_sym
      end

      def basepath(file)
        file.sub(Setting.root.to_s, '').sub(/.*#{CONFIG_PATH}\//, '')
      end

      def capture2e(*cmd)
        return puts cmd if Setting.local?
        puts cmd
        Open3.capture2e(*cmd)
      end

      def popen3(cmd_name, server, *args, &block)
        command = send(cmd_name, server, *args)
        return puts command if Setting.local?
        puts command if sun.debug
        Open3.popen3(command, &block)
      end

      def system!(*args)
        system(*args, exception: true)
      end

      def system(*args, exception: nil)
        return puts args if Setting.local?
        puts args if sun.debug
        unless (status = Kernel.system(*args)) || !exception
          puts args.map(&:to_s).map(&:red) unless sun.debug
          exit false
        end
        status
      end

      def exec(*args)
        return puts args if Setting.local?
        puts args if sun.debug
        Kernel.exec(*args)
      end

      def exit(*)
        puts 'Command failed'.red
        Kernel.exit(*)
      end

      def puts(*)
        Kernel.puts(*)
        true
      end
    end
  end
end

require 'sunzistrano/cli/bash'
require 'sunzistrano/cli/computer'
require 'sunzistrano/cli/multipass'
require 'sunzistrano/cli/rsync'
load 'Sunfile' if File.exist? 'Sunfile'
