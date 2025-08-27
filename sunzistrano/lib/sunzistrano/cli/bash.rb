require 'sunzistrano/context/bash'

module Sunzistrano
  BASH_SCRIPT = /^\w+[\w\/]+(\[|$)/
  BASH_HELPER = /^\w+\.[\w.]+(\[|$)/
  BASH_EXPORT = /^\w+=/

  Cli.class_eval do
    desc 'bash-list [--stage]', 'List bash scripts and helpers'
    method_options stage: :string
    def bash_list = do_bash_list

    desc 'bash [STAGE] [TASK] [--host] [--sudo] [--no-verbose]', 'Execute bash script(s) and/or helper function(s)'
    method_options host: :string, sudo: false, verbose: true
    def bash(stage, task) = do_bash(stage, task)

    no_tasks do
      def do_bash_list
        with_context(options.stage.presence || 'production', :deploy) do
          if sun.bash_scripts.any?
            puts 'scripts >'
            sun.bash_scripts.each{ |script| puts script.indent(2) }
          end
          if sun.bash_helpers.any?
            puts 'helpers >'
            sun.bash_helpers.each{ |helper| puts helper.indent(2) }
          end
        end
      end

      def do_bash(stage, task)
        with_context(stage, :deploy) do
          run_job_cmd :bash, task
        end
      end

      def bash?
        sun.deploy
      end

      alias_method :build_role_without_scripts, :build_role
      def build_role
        build_role_without_scripts
        used = Set.new
        if bash?
          copy_hooks :script
          (sun.bash_scripts + ['helper']).each do |file|
            used << (dst = bash_path("scripts/#{file}.sh"))
            create_file dst, <<~SH, force: true, verbose: sun.debug
              export script=#{file}
              export PWD_WAS=$(pwd)
              cd "#{bash_dir_remote}"
              source script_before.sh
              \n#{File.read(dst)}
              source script_after.sh
            SH
          end
        end
        remove_all_unused :script, used
        FileUtils.rmdir(bash_path('scripts')) unless bash?
      end

      def run_job_cmd(type, *args)
        raise 'run_job_cmd type cannot be "role"' if type.to_sym == :role
        Parallel.each(Array.wrap(options.host.presence || sun.servers), in_threads: Float::INFINITY) do |server|
          run_command :job_cmd, server, type, *args
        end
      end

      def job_cmd(server, type, *args)
        command = send "#{type}_remote_cmd", *args
        remote_cmd server, command.escape_single_quotes(:shell)
      end

      def bash_remote_cmd(task)
        split_unquoted(task).each_with_object(["export BASH_OUTPUT=#{sun.verbose.to_b}"]) do |token, memo|
          case token
          when BASH_SCRIPT
            name, args = parse_job(token)
            raise "script '#{name}' is not available" unless sun.bash_scripts.include? name
            memo << <<-SH.squish
              cd #{sun.deploy_path :current, BASH_DIR} &&
              #{'sudo -E' if sun.sudo} bash -e -u +H scripts/#{name}.sh #{args.join(' ')} 2>&1 |
              tee -a #{sun.deploy_path :current, BASH_LOG}
            SH
          when BASH_HELPER
            name, args = parse_job(token)
            raise "helper '#{name}' is not available" unless sun.bash_helpers.include? name
            memo << <<-SH.squish
              cd #{sun.deploy_path :current, BASH_DIR} &&
              export helper=#{name} &&
              #{'sudo -E' if sun.sudo} bash -e -u +H scripts/helper.sh #{args.join(' ')} 2>&1 |
              tee -a #{sun.deploy_path :current, BASH_LOG} && unset helper
            SH
          when BASH_EXPORT
            memo.unshift "export #{token}"
          else
            raise "invalid token '#{token}'"
          end
        end.join(' && ')
      end

      def split_unquoted(string)
        words = [['']]
        string.scan(/(?:([^"']+)|("[^"]*")|('[^']*'))/) do |word, double, single|
          if word
            segments = word.split(' ')
            words.last[-1] << segments.shift
            words << segments
          end
          words.last[-1] << double if double
          words.last[-1] << single if single
        end
        words.flatten
      end

      def parse_job(token)
        /^([^\[]+)\[(.*)\]$/ =~ token
        name, rest = $1, $2
        return token, [] unless name
        return name,  [] unless rest.present?
        args = []
        begin
          /\s*((?:[^\\,]|\\.)*?)\s*(?:,\s*(.*))?$/ =~ rest
          rest = $2
          args << $1.gsub(/\\(.)/, '\1')
        end while rest
        return name, args
      end
    end
  end
end
