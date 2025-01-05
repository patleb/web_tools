module Sunzistrano
  ERB_CLOUD_INIT = './cloud-init.yml'
  TMP_CLOUD_INIT = './tmp/cloud-init.yml'

  Cli.class_eval do
    desc 'up', 'Start Multipass instance(s)'
    def up
      do_up
    end

    desc 'halt', 'Stop Multipass instance(s)'
    def halt
      as_virtual do
        system "multipass stop #{vm_name}" if vm_state == :running
      end
    end

    desc 'destroy', 'Delete Multipass instance(s)'
    def destroy
      do_destroy
    end

    desc 'status', 'Output status of Multipass instance(s)'
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

    desc 'snapshot [ACTION] [--name]', 'Save/Restore/List/Delete Multipass snapshot(s)'
    method_options name: :string
    def snapshot(action)
      do_snapshot(action)
    end

    no_tasks do
      def do_up
        as_virtual do
          case vm_state
          when :null
            compile_cloud_init
            system "multipass launch #{sun.os_version} --name #{vm_name} #{vm_options}"
            add_virtual_host
          when :stopped
            system "multipass start #{vm_name}"
          end
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

      def do_snapshot(action)
        raise "snapshot action [#{action}] unsupported" unless %w(save restore list delete).include? action
        as_virtual do
          send "run_snapshot_#{action}_cmd"
        end
      end

      private

      def run_snapshot_save_cmd
        name = "--name #{sun.name}" if sun.name.present?
        cmd = case vm_state
        when :stopped
          "multipass snapshot #{name} #{vm_name}"
        when :running
          "multipass stop #{vm_name} && multipass snapshot #{name} #{vm_name} && multipass start #{vm_name}"
        else
          raise "vm state [#{vm_state}]"
        end
        system cmd
      end

      def run_snapshot_restore_cmd
        raise 'No snapshots' unless vm_snapshots
        if (name = sun.name).present?
          raise "No snapshot [#{name}]" unless vm_snapshots.has_key? name
        else
          name = vm_snapshots.sort_by{ |_name, info| info[:created_at] }.last.first
        end
        cmd = case vm_state
        when :stopped
          "multipass restore #{vm_name}.#{name} --destructive"
        when :running
          "multipass stop #{vm_name} && multipass restore #{vm_name}.#{name} --destructive && multipass start #{vm_name}"
        else
          raise "vm state [#{vm_state}]"
        end
        system cmd
      end

      def run_snapshot_list_cmd
        system "multipass list --snapshots | grep -E '^(Instance|#{vm_name})'"
      end

      def run_snapshot_delete_cmd
        raise 'Snapshot name required' unless (name = sun.name).present?
        raise "No snapshot [#{name}]" unless vm_snapshots&.has_key? name
        cmd = case vm_state
        when :stopped
          "multipass delete #{vm_name}.#{name} --purge"
        when :running
          "multipass stop #{vm_name} && multipass delete #{vm_name}.#{name} --purge && multipass start #{vm_name}"
        else
          raise "vm state [#{vm_state}]"
        end
        system cmd
      end

      def vm_state
        return :null unless vm_info
        vm_info[:state].downcase.to_sym
      end

      def vm_name
        "vm-#{sun.app.dasherize}"
      end

      def vm_options
        "--cpus #{sun.vm_cpu} --memory #{sun.vm_ram} --disk #{sun.vm_disk} --cloud-init=#{TMP_CLOUD_INIT}"
      end

      def vm_info
        @vm_info ||= begin
          return unless (json = `multipass info #{vm_name} --format=json`).present?
          return unless (hash = JSON.parse(json).dig('info', vm_name))
          hash.to_hwka
        end
      end

      def vm_snapshots
        @vm_snapshots ||= begin
          return unless (json = `multipass list --snapshots --format=json`).present?
          return unless (hash = JSON.parse(json).dig('info', vm_name))
          hash.each_with_object({}) do |(name, _info), memo|
            json = `multipass info #{vm_name}.#{name} --format=json`
            info = JSON.parse(json).dig('info', vm_name, 'snapshots', name)
            info['created'] = Time.parse(info['created']).in_time_zone('UTC')
            memo[name] = info.to_hwka
          end
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
        private_ip_file.write(ip)
      end

      def remove_virtual_host
        ip = private_ip
        if (ip_was = private_ip_file.read) && ip_was != ip
          puts "ip has changed [#{ip_was}] --> [#{ip}]".red
          ip = ip_was
        end
        yield
        system Sh.delete_lines! '/etc/hosts', /[^\d]#{ip}[^\d]/, sudo: true if ip
        private_ip_file.delete(false)
      end

      def private_ip
        vm_info[:ipv4].first
      end

      def private_ip_file
        Pathname.new('.multipass/private_ip')
      end
    end
  end
end
