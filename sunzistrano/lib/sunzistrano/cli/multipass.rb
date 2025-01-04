module Sunzistrano
  ERB_CLOUD_INIT = './cloud-init.yml'
  TMP_CLOUD_INIT = './tmp/cloud-init.yml'

  Cli.class_eval do
    desc 'up [--cluster] [--all]', 'Start Multipass instance(s)'
    method_options cluster: false, all: false
    def up
      do_up
    end

    desc 'halt [--cluster] [--all]', 'Stop Multipass instance(s)'
    method_options cluster: false, all: false
    def halt
      as_virtual do
        system "multipass stop #{vm_name}" if vm_state == :running
      end
    end

    desc 'destroy [--cluster] [--all]', 'Delete Multipass instance(s)'
    method_options cluster: false, all: false
    def destroy
      do_destroy
    end

    desc 'status [--cluster] [--all]', 'Output status of Multipass instance(s)'
    method_options cluster: false, all: false
    def status
      as_virtual do
        system "multipass info #{vm_name}"
      end
    end

    desc 'ssh [-c]', 'Shell into Multipass master instance (or execute -c command)'
    method_options c: :string
    def ssh
      do_ssh
    end

    desc 'ssh-add', 'Add Multipass ssh private key'
    def ssh_add
      as_virtual do
        exec 'ssh-add .multipass/private_key 2> /dev/null'
      end
    end

    no_tasks do
      def do_up
        as_virtual do
          cmd = case vm_state
          when :null
            compile_cloud_init
            "multipass launch #{sun.os_version} --name #{vm_name} #{vm_options}"
          when :stopped
            "multipass start #{vm_name}"
          else
            return
          end
          system cmd
          add_virtual_host
        end
      end

      def do_destroy
        as_virtual do
          cmd = case vm_state
          when :null
            return
          when :deleted
            "multipass purge"
          when :stopped
            "multipass delete #{vm_name} && multipass purge"
          when :running
            "multipass stop #{vm_name} && multipass delete #{vm_name} && multipass purge"
          else
            raise "vm state [#{vm_state}]"
          end
          remove_virtual_host do
            system cmd
          end
        end
      end

      def do_ssh
        as_virtual do
          case vm_state
          when :running
            if sun.c.present?
              exec "multipass exec #{vm_name} -- #{sun.c}"
            else
              exec "multipass shell #{vm_name}"
            end
          else
            raise "vm state [#{vm_state}]"
          end
        end
      end

      private

      def vm_state
        return :null unless vm_ssh_config
        vm_ssh_config[:state].downcase.to_sym
      end

      def vm_name
        "vm-#{sun.app.dasherize}"
      end

      def vm_options
        "--cpus #{sun.vm_cpu} --memory #{sun.vm_ram} --disk #{sun.vm_disk} --cloud-init=#{TMP_CLOUD_INIT}"
      end

      def vm_ssh_config
        @vm_ssh_config ||= begin
          return unless (json = `multipass info #{vm_name} --format=json`).present?
          return unless (hash = JSON.parse(json).dig('info', vm_name))
          hash.to_hwia
        end
      end

      def as_virtual(&block)
        with_context 'virtual', :provision, &block
      end

      def compile_cloud_init
        if (yml = Pathname.new(ERB_CLOUD_INIT)).exist?
          yml = YAML.safe_load(ERB.template(yml, binding)).to_hwia
        else
          yml = {}
        end
        keys = yml[:ssh_authorized_keys] || []
        yml[:ssh_authorized_keys] = keys | Setting.authorized_keys
        Pathname.new(TMP_CLOUD_INIT).write(yml.to_hash.pretty_yaml)
      end

      def add_virtual_host
        ip = private_ip
        system Sh.append_host "#{Host::VIRTUAL}-#{ip}", ip, sun.server_host
      end

      def remove_virtual_host
        ip = private_ip
        yield
        system Sh.delete_lines! '/etc/hosts', /[^\d]#{ip}[^\d]/, sudo: true
      end

      def private_ip
        vm_ssh_config[:ipv4].first
      end
    end
  end
end
