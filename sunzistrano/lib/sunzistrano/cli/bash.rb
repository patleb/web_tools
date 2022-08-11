require 'sunzistrano/context/bash'

module Sunzistrano
  BASH_SCRIPT = /^\w+[\w\/]+(\[|$)/
  BASH_HELPER = /^\w+\.[\w.]+(\[|$)/
  BASH_EXPORT = /^\w+=/

  Cli.class_eval do
    desc 'bash-list [--stage]', 'List bash scripts and helpers'
    method_options stage: :string
    def bash_list
      do_bash_list(options.stage.presence || 'production')
    end

    desc 'bash [STAGE] [TASK] [--host] [--sudo] [--no-verbose]', 'Execute bash script(s) and/or helper function(s)'
    method_options host: :string, sudo: false, verbose: true
    def bash(stage, task)
      do_bash(stage, task)
    end

    no_tasks do
      def do_bash_list(stage)
        with_context(stage, :deploy) do
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

      alias_method :build_role_without_scripts, :build_role
      def build_role
        build_role_without_scripts
        copy_hooks :script
        used = Set.new
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
        remove_all_unused :script, used
      end

      def bash_remote_cmd(task)
        task.shellsplit.each_with_object(["BASH_OUTPUT=#{sun.verbose.to_b}"]) do |token, memo|
          case token
          when BASH_SCRIPT
            name, args = parse_bash_task(token)
            raise "script '#{name}' is not available" unless sun.bash_scripts.include? name
            memo << <<-SH.squish
              cd #{sun.deploy_path :current, BASH_DIR} &&
              #{'sudo -E' if sun.sudo} bash -e -u +H scripts/#{name}.sh #{args.join(' ').shellescape} |&
              tee -a #{sun.deploy_path :current, BASH_LOG}
            SH
          when BASH_HELPER
            name, args = parse_bash_task(token)
            raise "helper '#{name}' is not available" unless sun.bash_helpers.include? name
            memo << <<-SH.squish
              cd #{sun.deploy_path :current, BASH_DIR} &&
              export helper=#{name} &&
              #{'sudo -E' if sun.sudo} bash -e -u +H scripts/helper.sh #{args.join(' ').shellescape} |&
              tee -a #{sun.deploy_path :current, BASH_LOG} && unset helper
            SH
          when BASH_EXPORT
            name, value = token.split('=', 2)
            memo << "export #{name}=#{value.shellescape}"
          else
            raise "invalid token '#{token}'"
          end
        end.join(' && ')
      end

      def parse_bash_task(token)
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
