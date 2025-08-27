require 'sunzistrano/context/computer'

module Sunzistrano
  COMPUTER_ACTIONS = %w(compile install bash backup restore)

  Cli.class_eval do
    desc 'computer [ACTION] [--recipe] [--force] [--task] [--sudo] [--no-verbose]', "#{COMPUTER_ACTIONS.map(&:upcase_first).join('/')} for Computer"
    method_options recipe: :string, force: false, task: :string, sudo: false, verbose: true
    def computer(action) = do_computer(action)

    no_tasks do
      def do_computer(action)
        raise "--task is required for bash action" if action == 'bash' && options.task.blank?
        raise "computer action [#{action}] unsupported" unless COMPUTER_ACTIONS.include? action
        as_computer do
          send "run_computer_#{action}_cmd"
        end
      end

      alias_method :bash_without_computer?, :bash?
      def bash?
        bash_without_computer? || sun.computer?
      end

      private

      def run_computer_compile_cmd
        compile_all
      end

      def run_computer_install_cmd
        compile_all
        before_role
        run_command :computer_install_cmd, sun.server_host
        after_role
      end

      def run_computer_bash_cmd
        run_command :computer_bash_cmd, sun.server_host
      end

      def computer_install_cmd(*)
        <<-SH.squish
          mkdir -p #{sun.computer_path} && start=$(mktemp) && sleep 0.01 &&
          ln -nsf #{sun.provision_path} #{sun.provision_path :current} &&
          cp -rTf --no-preserve=timestamps #{bash_dir} #{sun.computer_path} && cd #{sun.computer_path} &&
          #{'sudo' if sun.sudo} bash -e -u +H role.sh 2>&1 |
          tee -a #{sun.provision_path BASH_LOG} && cd #{sun.computer_path} &&
          find . -depth ! -cnewer $start -print0 | sponge /dev/stdout | xargs -r0 rm -d > /dev/null 2>&1 && rm -f $start
        SH
      end

      def computer_bash_cmd(*)
        bash_remote_cmd(sun.task)
      end

      def as_computer(&block)
        with_context 'computer', :computer, &block
      end
    end
  end
end
