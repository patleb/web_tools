module Sunzistrano
  MULTIPASS_DIR = '.multipass'
  MULTIPASS_INFO = "#{MULTIPASS_DIR}/metadata.yml"
  ERB_CLOUD_INIT = './cloud-init.yml'
  TMP_CLOUD_INIT = './tmp/cloud-init.yml'
  SNAPSHOT_ACTIONS = %w(save restore list delete)

  Cli.class_eval do
    desc 'up [--id] [--master] [--cluster]', 'Start Multipass instance(s)'
    method_options id: :numeric, master: false, cluster: false
    def up
      do_up
    end

    desc 'halt [--id] [--master] [--cluster] [--force]', 'Stop Multipass instance(s)'
    method_options id: :numeric, master: false, cluster: false, force: false
    def halt
      do_halt
    end

    desc 'destroy [--id] [--master] [--cluster]', 'Delete Multipass instance(s)'
    method_options id: :numeric, master: false, cluster: false
    def destroy
      do_destroy
    end

    desc 'status [--id] [--master] [--cluster]', 'Output status of Multipass instance(s)'
    method_options id: :numeric, master: false, cluster: false
    def status
      do_status
    end

    desc 'ssh [--id] [-c]', 'Shell into Multipass instance (or execute -c command)'
    method_options id: :numeric, c: :string
    def ssh
      do_ssh
    end

    desc 'ssh-add', 'Add Multipass ssh private key'
    def ssh_add
      as_virtual do
        exec "ssh-add #{MULTIPASS_DIR}/private_key 2> /dev/null"
      end
    end

    desc 'snapshot [ACTION] [--name]', "#{SNAPSHOT_ACTIONS.map(&:upcase_first).join('/')} Multipass master's snapshot(s)"
    method_options name: :string
    def snapshot(action)
      do_snapshot(action)
    end

    no_tasks do
      def do_up
        as_virtual do
          Parallel.each(vm_ids!) do |name, id|
            case vm_state id
            when :null
              add_virtual_host id do
                if id == 0
                  compile_cloud_init
                  system! "multipass launch #{sun.os_version} --name #{name} #{vm_options}"
                else
                  system! "multipass clone #{vm_name} && multipass start #{name}"
                end
              end
            when :stopped
              system! "multipass start #{name}"
            end
          end
        end
      end

      def do_halt
        as_virtual do
          Parallel.each(vm_ids) do |name, id|
            case vm_state id
            when :running
              system! "multipass stop #{name} #{'--force' if sun.force}"
            when :null, :deleted, :stopped
              # do nothing
            else
              system! "multipass stop #{name} --force"
            end
          end
        end
      end

      def do_destroy
        as_virtual do
          Parallel.each(vm_ids) do |name, id|
            cmd = case vm_state id
            when :null
              return
            when :deleted
              "multipass purge"
            when :stopped
              "multipass delete #{name} && multipass purge"
            when :running
              "multipass stop #{name} && multipass delete #{name} && multipass purge"
            else
              raise "vm state [#{vm_state id}]"
            end
            remove_virtual_host id do
              system! cmd
            end
          end
        end
      end

      def do_status
        as_virtual do
          vm_ids.each do |vm, id|
            puts "---------------- #{id}"
            system "multipass info #{vm}"
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
        raise "snapshot action [#{action}] unsupported" unless SNAPSHOT_ACTIONS.include? action
        as_virtual do
          send "run_snapshot_#{action}_cmd"
        end
      end

      private

      def as_virtual(&block)
        with_context 'virtual', :provision, &block
        vm_info!
      end

      def run_snapshot_save_cmd
        name = "--name #{vm_snapshot sun.name}" if sun.name.present?
        cmd = case vm_state
        when :stopped
          "multipass snapshot #{name} #{vm_name}"
        when :running
          "multipass stop #{vm_name} && multipass snapshot #{name} #{vm_name} && multipass start #{vm_name}"
        else
          raise "vm state [#{vm_state}]"
        end
        system! cmd
      end

      def run_snapshot_restore_cmd
        raise 'No snapshots' unless vm_snapshots
        if (name = vm_snapshot sun.name).present?
          raise "No snapshot [#{name}]" unless vm_snapshots.has_key? name
        else
          name = vm_snapshots.sort_by{ |_name, info| info[:created] }.last.first
        end
        cmd = case vm_state
        when :stopped
          "multipass restore #{vm_name}.#{name} --destructive"
        when :running
          "multipass stop #{vm_name} && multipass restore #{vm_name}.#{name} --destructive && multipass start #{vm_name}"
        else
          raise "vm state [#{vm_state}]"
        end
        system! cmd
      end

      def run_snapshot_list_cmd
        system "multipass list --snapshots | grep -E '^(Instance|#{vm_name})'"
      end

      def run_snapshot_delete_cmd
        raise 'Snapshot name required' unless (name = vm_snapshot sun.name)
        raise "No snapshot [#{name}]" unless vm_snapshots&.has_key? name
        cmd = case vm_state
        when :stopped
          "multipass delete #{vm_name}.#{name} --purge"
        when :running
          "multipass stop #{vm_name} && multipass delete #{vm_name}.#{name} --purge"
        else
          raise "vm state [#{vm_state}]"
        end
        system! cmd
      end

      def vm_snapshots
        @vm_snapshots ||= begin
          return unless (json = `multipass list --snapshots --format=json`).present?
          return unless (hash = JSON.parse(json).dig('info', vm_name))
          hash.each_with_object({}) do |(name, _info), memo|
            name = vm_snapshot(name)
            json = `multipass info #{vm_name}.#{name} --format=json`
            info = JSON.parse(json).dig('info', vm_name, 'snapshots', name)
            info['created'] = Time.parse(info['created']).in_time_zone('UTC')
            memo[name] = info.to_hwka
          end
        end
      end

      def vm_snapshot(name)
        return unless name.present?
        name.parameterize.dasherize.downcase
      end

      def vm_options
        "--cpus #{sun.vm_cpu} --memory #{sun.vm_ram} --disk #{sun.vm_disk} --cloud-init=#{TMP_CLOUD_INIT}"
      end

      def compile_cloud_init
        if (yml = Pathname.new(ERB_CLOUD_INIT)).exist?
          yml = YAML.safe_load(ERB.template(yml, binding)).to_hwia
        else
          yml = {}
        end
        keys = Array.wrap(yml[:ssh_authorized_keys])
        yml[:ssh_authorized_keys] = keys | Setting.authorized_keys
        yml[:manage_etc_hosts] = false unless yml.has_key? :manage_etc_hosts
        Pathname.new(TMP_CLOUD_INIT).write(yml.to_hash.pretty_yaml)
      end

      def add_virtual_host(*)
        ip_was = vm_ip(*)
        yield
        ip = vm_ip!(*)
        if ip_was != ip
          puts "ip has changed [#{ip_was}] --> [#{ip}]".red
        end
        system! Sh.delete_lines!('/etc/hosts', /[^\d]#{ip}[^\d]/, sudo: true) if ip_was
        system! Sh.append_host("#{Host::VIRTUAL}-#{ip}", ip, vm_server_host(*))
      end

      def remove_virtual_host(*)
        ip_was = vm_ip(*)
        yield
        if (ip = vm_ip!(*)) && ip_was != ip
          puts "ip has changed [#{ip_was}] --> [#{ip}]".red
        end
        [ip_was, ip].each do |ip|
          system! Sh.delete_lines!('/etc/hosts', /[^\d]#{ip}[^\d]/, sudo: true) if ip
        end
      end

      def vm_server_host(id = nil)
        name = sun.server_host
        return name if (id = id || sun.id).nil? || id == 0
        "cluster-#{id}.#{name}"
      end

      def vm_name(id = nil)
        name = "vm-#{sun.app.dasherize}"
        return name if (id = id || sun.id).nil? || id == 0
        "#{name}-clone#{id}"
      end

      def vm_state(*)
        return :null unless (vm = vm_info[vm_name(*)])
        vm[:state].downcase.to_sym
      end

      def vm_ip(*)
        vm_info.dig(vm_name(*), :ip)
      end

      def vm_ip!(*)
        vm_info!.dig(vm_name(*), :ip)
      end

      def vm_ids
        @vm_ids ||= begin
          ids = vm_info.map{ |vm, _| [vm, vm.split('-clone').last.to_i] }.to_h
          ids = ids.slice(ids.key(sun.id)) if sun.id
          ids = ids.slice(ids.key(0)) if sun.master
          ids = ids.except(ids.key(0)) if sun.cluster
          ids
        end
      end

      def vm_ids!
        ids = ([vm_name] + sun.vm_clusters.times.map{ |i| vm_name(i + 1) }).map.with_index{ |name, i| [name, i] }.to_h
        ids = ids.slice(ids.key(sun.id)) if sun.id
        ids = ids.slice(ids.key(0)) if sun.master
        ids = ids.except(ids.key(0)) if sun.cluster
        ids
      end

      def vm_info
        @vm_info ||= vm_info!
      end

      def vm_info!
        @vm_info = nil
        metadata = (file = Pathname.new(MULTIPASS_INFO)).exist? && YAML.safe_load(file.read) || {}
        info = ([vm_name] + sun.vm_clusters.times.map{ |i| vm_name(i + 1) }).each_with_object({}) do |vm, hash|
          next metadata.delete(vm) unless (json = `multipass info #{vm} --format=json 2>/dev/null`).present?
          next unless (info = JSON.parse(json).dig('info', vm)).present?
          ip_was = metadata.dig(vm, 'ip')
          metadata[vm] = hash[vm] = info
          metadata[vm]['ip'] = info.dig('ipv4', 0) || ip_was
        end
        Pathname.new(MULTIPASS_INFO).write(metadata.to_yaml)
        info.to_hwia
      end
    end
  end
end
