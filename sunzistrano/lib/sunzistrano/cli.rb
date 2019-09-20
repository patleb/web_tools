# TODO https://github.com/christophemaximin/executable_mock
module Sunzistrano
  class Cli < Thor
    include Thor::Actions

    desc 'provision [stage] [role] [--recipe] [--vagrant-name] [--username] [--password]', 'Provision sunzistrano project'
    method_options recipe: :string, vagrant_name: :string, username: :string, password: :string
    def provision(stage, role = 'system')
      do_provision(stage, role)
    end

    desc 'rollback [stage] [role] [--recipe] [--vagrant-name] [--username] [--password]', 'Rollback sunzistrano recipe'
    method_options recipe: :required, vagrant_name: :string, username: :string, password: :string
    def rollback(stage, role = 'system')
      do_provision(stage, role, rollback: true)
    end

    desc 'compile [stage] [role] [--recipe] [--vagrant-name] [--rollback]', 'Compile sunzistrano project'
    method_options recipe: :string, vagrant_name: :string, rollback: false
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
        send_commands(provision_cmd)
      end

      def do_compile(stage, role, **custom_options)
        load_config(stage, role, **custom_options)
        copy_remote_files
        copy_local_files
        build_role
      end

      def do_download(stage, role)
        load_config(stage, role)
        path = @sun.path
        ref = Pathname.new(Dir.pwd).expand_path
        ref = ref.join('config', 'provision', 'files', "#{path.delete_prefix('/')}.ref")
        FileUtils.mkdir_p File.dirname(ref)
        if @sun.saved
          path = "/home/#{@sun.username}/#{@sun.DEFAULTS_DIR}/#{path.gsub(/\//, '~')}"
        end
        unless system download_cmd(path, ref)
          puts "Cannot transfer [#{path}] to [#{ref}]".color(:red).bright
        end
      end

      def load_config(stage, role, **custom_options)
        validate_config_presence!
        @sun = Sunzistrano::Config.new(stage, role, **options.symbolize_keys, **custom_options)
      end

      def copy_remote_files
        %w(files helpers recipes roles).each do |type|
          (@sun["remote_#{type}"] || []).each do |file|
            get_remote_file(file, type)
          end
        end
      end

      def copy_local_files
        basenames = "config/provision/{files,helpers,recipes,roles}/**/*"

        dirnames = [basenames]
        dirnames << @sun.local_dir.join(basenames).to_s if @sun.local_dir
        (@sun.gems || []).each do |name|
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
          compile_file File.expand_path(file), expand(:provision, file), force: true
        end

        (@sun.local_files || []).each do |file|
          compile_file File.expand_path(file), expand(:provision, "files/local/#{File.basename(file)}"), force: true
        end
      end

      def build_role
        around = %i(before after).each_with_object({}) do |hook, memo|
          path = expand(:provision, "role_#{hook}.sh")
          compile_file expand(:root, "role_#{hook}.sh"), path, force: true
          memo[hook] = File.binread(path)
        end
        content = around[:before] << "\n" << File.binread(expand(:provision, "roles/#{@sun.role}.sh")) << "\n" << around[:after]

        create_file expand(:provision, "role.sh"), content, force: true
        compile_file expand(:root, "sun.sh"), expand(:provision, "sun.sh"), force: true
      end

      def compile_file(*args, **options)
        # TODO compare .esh with .ref file for bash/erb unnescaped characters
        template *args, **options
        if args[0].to_s.end_with? '.pow'
          compiled_pow = args[1]
          compiled_sh = compiled_pow.sub(/\.pow$/, '.sh')
          `powscript --compile #{compiled_pow} > #{compiled_sh}`
        end
      end

      def validate_version!
        unless @sun.lock == Sunzistrano::VERSION
          abort "Sunzistrano version [#{Sunzistrano::VERSION}] is different from locked version [#{@sun.lock}]"
        end
      end

      def validate_config_presence!
        abort_with 'You must have a provision.yml'unless File.exist?(Sunzistrano::Config.provision_yml)
      end

      def get_remote_file(file, type)
        file_path = expand("#{type}/remote/#{File.basename(file)}")
        return if File.exist? file_path
        get file, file_path
      end

      def send_commands(commands)
        `ssh-keygen -R #{@sun.server} 2> /dev/null`

        Open3.popen3(commands) do |stdin, stdout, stderr|
          stdin.close
          t = Thread.new do
            while (line = stderr.gets)
              print line.color(:red)
            end
          end
          while (line = stdout.gets)
            print line.color(:green)
          end
          t.join
        end
      end

      def provision_cmd
        <<~CMD
          #{ssh_add_cmd} cd .provision && tar cz . | #{"sshpass -p #{@sun.password}" if @sun.password} ssh \
          -o 'StrictHostKeyChecking no' -o LogLevel=ERROR \
          #{@sun.username}@#{@sun.server} \
          #{"-p #{@sun.port}" if @sun.port} \
          '#{provision_remote_cmd} '#{'&& (cd .. && rm -rf .provision) || (cd .. && rm -rf .provision)' unless @sun.debug}
        CMD
      end

      def provision_remote_cmd
        <<~CMD
          rm -rf ~/#{@sun.PROVISION_DIR} &&
          mkdir ~/#{@sun.PROVISION_DIR} &&
          cd ~/#{@sun.PROVISION_DIR} &&
          tar xz &&
          #{'sudo' if @sun.sudo} bash role.sh |& tee -a ~/#{@sun.PROVISION_LOG}
        CMD
      end

      def download_cmd(path, ref)
        <<~CMD
          #{ssh_add_cmd} rsync --rsync-path='sudo rsync' -azvh -e "ssh \
          -o 'StrictHostKeyChecking no' -o LogLevel=ERROR \
          #{"-p #{@sun.port}" if @sun.port}" \
          #{@sun.username}@#{@sun.server}:#{path} #{ref}
        CMD
      end

      def ssh_add_cmd
        <<~CMD if @sun.pkey.present?
          if [ $(ps ax | grep [s]sh-agent | wc -l) -eq 0 ]; then \
            eval $(ssh-agent); \
          fi \
          && ssh-add #{@sun.pkey} 2> /dev/null &&
        CMD
      end

      def provision?(file, others)
        File.file?(file) &&
          !file[/\.keep$/] &&
          !file[/\/roles\/(?!(#{@sun.role}|hook_\w+)\.sh)/] &&
          others.none?{ |f| file.end_with? name_of(f) }
      end

      def expand(type, file = type)
        case type
        when :root
          file = Sunzistrano.root.join("config/provision/#{name_of(file)}")
        when :provision
          file = ".provision/#{name_of(file)}"
        else
          file = "config/provision/#{name_of(file)}"
        end
        File.expand_path(file)
      end

      def name_of(file)
        file.sub(/.*config\/provision\//, '')
      end

      def abort_with(text)
        puts text.color(:red).bright
        abort
      end
    end
  end
end
