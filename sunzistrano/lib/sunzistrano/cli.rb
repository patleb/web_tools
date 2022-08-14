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

  def self.owner_path(dir, name = nil)
    if name
      const_name = dir.to_s.upcase
      name = const_name.end_with?('_DIR') && const_defined?(const_name) ? "#{const_get(const_name)}/#{name}" : dir
    end
    "/home/#{Setting[:owner_name]}/#{Setting.stage}/#{name}"
  end

  class Cli < Thor
    include Thor::Actions

    attr_reader :sun

    def self.source_root
      File.expand_path('../../', __FILE__)
    end

    def self.exit_on_failure?
      true
    end

    desc 'deploy [STAGE] [--system] [--rollback] [--recipe] [--no-sync] [--force]', 'Deploy application'
    method_options system: false, rollback: false, recipe: :string, sync: true, force: false
    def deploy(stage)
      raise '--recipe is required for rollback' if options.rollback && options.recipe.blank?
      do_provision(stage, :deploy)
    end

    desc 'provision [STAGE] [--specialize] [--rollback] [--recipe] [--reboot] [--new-host]', 'Provision system'
    method_options specialize: false, rollback: false, recipe: :string, reboot: false, new_host: false
    def provision(stage)
      raise '--recipe is required for rollback' if options.rollback && options.recipe.blank?
      do_provision(stage, :provision)
    end

    desc 'compile [STAGE] [--deploy] [--system] [--specialize] [--rollback] [--recipe] [--reboot]', 'Compile provisioning'
    method_options deploy: false, system: false, specialize: false, rollback: false, recipe: :string, reboot: false
    def compile(stage)
      do_compile(stage)
    end

    desc 'reset_ssh [STAGE]', 'Reset ssh known hosts'
    def reset_ssh(stage)
      do_reset_ssh(stage)
    end

    no_tasks do
      def do_provision(stage, role)
        do_compile(stage, role)
        run_role_cmd
      end

      def do_compile(stage, role = nil)
        with_context(stage, role) do
          raise 'local and remote commits differ' if out_of_sync?
          copy_files
          build_helpers
          build_role
        end
      end

      def do_reset_ssh(stage)
        with_context(stage) do
          run_reset_known_hosts
        end
      end

      def with_context(stage, role = nil)
        env, app = stage.split('-', 2)
        role ||= options.deploy ? :deploy : :provision
        Setting.with(env: env, app: app) do
          @sun = Sunzistrano::Context.new(role, **options.symbolize_keys)
          yield
        end
      end

      def out_of_sync?
        sun.deploy && sun.sync && sun.revision != `git rev-parse HEAD`.strip
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
          src = Sunzistrano.root.join(CONFIG_PATH, basename(file)).expand_path
          dst = bash_path(file)
          copy_file src, dst, force: true, verbose: sun.debug
        end
      end

      def remove_all_unused(type, used)
        Dir[bash_path("#{type}s/**/*.sh")].each do |file|
          remove_file file, verbose: false unless used.include? file
        end
        Dir[bash_path("#{type}s/**/*")].select{ |dir| File.directory? dir }.reverse_each do |dir|
          next unless (Dir.entries(dir) - %w(. ..)).empty?
          FileUtils.rmdir(dir)
        end
      end

      def run_role_cmd
        Parallel.each(sun.servers, in_threads: Float::INFINITY) do |server|
          run_command :role_cmd, server
        end
        run_reset_known_hosts if sun.new_host
        FileUtils.rm_rf(sun.deploy ? File.dirname(bash_dir) : bash_dir) unless sun.debug
      end

      def run_reset_known_hosts
        return if Setting.env? :development, :test
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
        popen3(cmd_name, server, *args) do |stdin, stdout, stderr|
          stdin.close
          error = Thread.new do
            while (line = stderr.gets)
              if cmd_name == :role_cmd && line.start_with?('flock: failed')
                print "[#{server}] Already running -- : #{line.red}"
              else
                print "[#{server}] #{line.red}"
              end
            end
          end
          while (line = stdout.gets)
            if cmd_name == :role_cmd && line.start_with?('flock:')
              print "[#{server}] Already running -- : #{line.red}" if line.start_with? 'flock: failed'
            else
              print "[#{server}] #{line}"
            end
          end
          puts "[#{server}] #{Time.now.to_s.yellow}" unless options.verbose == false
          error.join
        end
      end

      def role_cmd(server)
        no_strict_host_key_checking = "-o 'StrictHostKeyChecking no'" if sun.new_host
        <<-SH.squish
          #{ssh_add_vagrant}
          cd #{bash_dir} && tar cz . |
          #{ssh} #{no_strict_host_key_checking} #{ssh_proxy} #{sun.ssh_user}@#{server} '#{role_remote_cmd}'
        SH
      end

      def role_remote_cmd
        <<-SH.squish
          mkdir -p #{bash_dir_remote} && cd #{bash_dir_remote} && start=$(mktemp) &&
          flock --verbose -n #{sun.deploy_path 'role.lock'} tar xz &&
          flock --verbose -n #{sun.deploy_path 'role.lock'} #{'sudo' if sun.sudo} bash -e -u +H role.sh |&
          tee -a #{sun.provision_path BASH_LOG} && cd #{bash_dir_remote} &&
          find . -depth ! -cnewer $start -print0 | sponge /dev/stdout | xargs -r0 rm -d && rm -f $start
        SH
      end

      def ssh
        "ssh #{"-p #{sun.ssh_port}" if sun.ssh_port} -o LogLevel=ERROR"
      end

      def ssh_proxy
        "-o ProxyCommand='ssh -W %h:%p #{sun.ssh_user}@#{sun.server_host}'" if sun.server_cluster?
      end

      def ssh_add_vagrant
        <<-SH.squish if sun.env.vagrant?
          if [ $(ps ax | grep [s]sh-agent | wc -l) -eq 0 ]; then
            eval $(ssh-agent);
          fi
          && ssh-add .vagrant/private_key 2> /dev/null &&
        SH
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
        @bash_dir ||= [BASH_DIR, sun.revision, sun.stage].compact.join('/')
      end

      def bash_dir_remote
        sun.provision_path BASH_DIR
      end

      def basetype(file)
        basename(file).split('/').first.delete_suffix('s').to_sym
      end

      def basename(file)
        file.sub(/.*#{CONFIG_PATH}\//, '')
      end

      def capture2e(*cmd)
        return puts cmd if Setting.env? :development, :test
        puts cmd
        Open3.capture2e(*cmd)
      end

      def popen3(cmd_name, server, *args, &block)
        command = send(cmd_name, server, *args)
        return puts command if Setting.env? :development, :test
        puts command if sun.debug
        Open3.popen3(command, &block)
      end

      def system(*args)
        return puts args if Setting.env? :development, :test
        puts args if sun.debug
        Kernel.system(*args)
      end

      def exec(*args)
        return puts args if Setting.env? :development, :test
        puts args if sun.debug
        Kernel.exec(*args)
      end
    end
  end
end

require 'sunzistrano/cli/bash'
require 'sunzistrano/cli/rsync'
load 'Sunfile' if File.exist? 'Sunfile'
