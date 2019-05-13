# TODO https://github.com/christophemaximin/executable_mock
module Sunzistrano
  class Cli < Thor
    include Thor::Actions

    desc 'deploy [stage] [role] [--recipe] [--vagrant-ssh] [--username] [--password]', 'Deploy sunzistrano project'
    method_options recipe: :string, vagrant_ssh: :string, username: :string, password: :string
    def deploy(stage, role)
      do_deploy(stage, role)
    end

    desc 'rollback [stage] [role] [recipe] [--vagrant-ssh] [--username] [--password]', 'Rollback sunzistrano recipe'
    method_options vagrant_ssh: :string, username: :string, password: :string
    def rollback(stage, role, recipe)
      do_deploy(stage, role, recipe: recipe, rollback: true)
    end

    desc 'compile [stage] [role] [--recipe] [--vagrant-ssh] [--rollback]', 'Compile sunzistrano project'
    method_options recipe: :string, vagrant_ssh: :string, rollback: false
    def compile(stage, role)
      do_compile(stage, role)
    end

    desc 'download [stage] [role] [path] [--saved]', 'Dowload file meant to be used as .ref template'
    method_options saved: false
    def download(stage, role, path)
      do_download(stage, role, path)
    end

    no_tasks do
      def self.source_root
        File.expand_path('../../', __FILE__)
      end

      def do_deploy(stage, role, **custom_options)
        do_compile(stage, role, **custom_options)

        validate_version!

        send_commands(deploy_commands)
      end

      def do_compile(stage, role, **custom_options)
        load_config(stage, role, **custom_options)
        copy_remote_files
        copy_local_files
        build_role
      end

      def do_download(stage, role, path)
        load_config(stage, role)
        ref = Pathname.new(Dir.pwd).expand_path
        ref = ref.join('config', 'provision', 'files', "#{path.sub(/^\//, '')}.ref")
        if @sun.saved
          path = "/home/#{@sun.username}/#{@sun.DEFAULTS_DIR}/#{path.gsub(/\//, '~')}"
        end

        unless system download_commands(path, ref)
          puts "Cannot transfer [#{path}] to [#{ref}]".color(:red).bright
        end
      end

      def do_concat
        # TODO
        # https://github.com/geerlingguy/docker-ubuntu1604-ansible
        # http://alesnosek.com/blog/2016/09/12/first-impressions-about-ansible-container/
        # replace source 'recipes/...', mv 'files/...', cp 'files/...' by actual content
        # FROM ruby:2.3-alpine
        # COPY ansible ansible
        # RUN apk add --no-cache ansible && ansible-playbook ansible/build.yml -vv
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
          next unless (path = Gem.loaded_specs[name].try(:gem_dir))
          require "#{name}/sunzistrano" rescue nil
          dirnames << Pathname.new(path).expand_path.join(basenames).to_s
        end
        dirnames << Sunzistrano.root.join(basenames).to_s

        files = []
        dirnames.each do |dirname|
          files += Dir[dirname].select{ |f| provision? f, files }
        end

        files.each do |file|
          compile_file File.expand_path(file), compiled(file), force: true
        end

        (@sun.local_files || []).each do |file|
          compile_file File.expand_path(file), compiled("files/local/#{File.basename(file)}"), force: true
        end
      end

      def build_role
        around = %i(before after).each_with_object({}) do |hook, memo|
          path = compiled("role_#{hook}.sh")
          compile_file based("role_#{hook}.sh", root: true), path, force: true
          memo[hook] = File.binread(path)
        end
        content = around[:before] << "\n" << File.binread(compiled("roles/#{@sun.role}.sh")) << "\n" << around[:after]

        create_file compiled("role.sh"), content, force: true
        compile_file based("sun.sh", root: true), compiled("sun.sh"), force: true
      end

      def compile_file(*args, **options)
        # TODO scan .esh file for bash/erb unnescaped characters
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
        file_path = based("#{type}/remote/#{File.basename(file)}")
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

      def deploy_commands
        if @sun.vagrant_ssh?
          "cd .deploy && tar cz . | (cd .. && vagrant ssh #{@sun.vagrant_ssh} -- '#{deploy_remote_commands}')"
        else
          <<~BASH
            #{"eval $(ssh-agent) && ssh-add #{@sun.pkey} 2> /dev/null &&" if @sun.pkey.present?}
            cd .deploy && tar cz . | #{"sshpass -p #{@sun.password}" if @sun.password} ssh \
            -o 'StrictHostKeyChecking no' \
            #{@sun.username}@#{@sun.server} \
            #{"-p #{@sun.port}" if @sun.port} \
            '#{deploy_remote_commands}' && (cd .. && rm -rf .deploy) || (cd .. && rm -rf .deploy)
          BASH
        end
      end

      def deploy_remote_commands
        <<~BASH
          rm -rf ~/#{@sun.DEPLOY_DIR} &&
          mkdir ~/#{@sun.DEPLOY_DIR} &&
          cd ~/#{@sun.DEPLOY_DIR} &&
          tar xz &&
          #{'sudo' if @sun.sudo} bash role.sh |& tee -a ~/#{@sun.DEPLOY_LOG}
        BASH
      end

      def download_commands(path, ref)
        <<~BASH
          #{"eval $(ssh-agent) && ssh-add #{@sun.pkey} 2> /dev/null &&" if @sun.pkey.present?}
          rsync --rsync-path='sudo rsync' -azvh -e "ssh \
          -o 'StrictHostKeyChecking no' \
          #{"-p #{@sun.port}" if @sun.port}" \
          #{@sun.username}@#{@sun.server}:#{path} #{ref}
        BASH
      end

      def provision?(file, others)
        File.file?(file) &&
          !file[/\.keep$/] &&
          !file[/\/roles\/(?!(#{@sun.role}|hook_\w+)\.sh)/] &&
          others.none?{ |f| file.end_with? f }
      end

      def based(file, root: false)
        file = "config/provision/#{file.sub(/.*config\/provision\//, '')}"
        File.expand_path(root ? Sunzistrano.root.join(file) : file)
      end

      def compiled(file)
        File.expand_path(".deploy/#{file.sub(/.*config\/provision\//, '')}")
      end

      def abort_with(text)
        puts text.color(:red).bright
        abort
      end
    end
  end
end
