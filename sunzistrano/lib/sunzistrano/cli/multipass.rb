module Sunzistrano
  MULTIPASS_DIR  = Pathname.new('.multipass')
  MULTIPASS_KEY  = MULTIPASS_DIR.join('key')
  MULTIPASS_INFO = MULTIPASS_DIR.join('info.yml')
  MULTIPASS_INFO_KEYS = %w(ip cpu_count ram_gb ram_used disk_gb disk_used snapshot)
  ERB_CLOUD_INIT = './cloud-init.yml'
  TMP_CLOUD_INIT = './tmp/cloud-init.yml'
  SNAPSHOT_ACTIONS = %w(save restore list delete)

  Cli.class_eval do
    desc 'up [-i] [--master] [--cluster]', 'Start Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false
    def up
      do_up
    end

    desc 'halt [-i] [--master] [--cluster] [--force]', 'Stop Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false, force: false
    def halt
      do_halt
    end

    desc 'destroy [-i] [--master] [--cluster]', 'Delete Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false
    def destroy
      do_destroy
    end

    desc 'status [-i] [--master] [--cluster]', 'Output status of Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false
    def status
      do_status
    end

    desc 'resize [--cpu] [--ram] [--disk]', 'Resize Multipass instance(s)'
    method_options cpu: false, ram: false, disk: false
    def resize
      do_resize
    end

    desc 'ssh [-i] [-c]', 'Shell into Multipass instance (or execute -c command)'
    method_options i: :numeric, c: :string
    def ssh
      do_ssh
    end

    desc 'ssh-add', 'Add Multipass ssh private key'
    def ssh_add
      do_add_ssh
    end

    desc 'snapshot [ACTION] [--name]', "#{SNAPSHOT_ACTIONS.map(&:upcase_first).join('/')} Multipass master's snapshot(s)"
    method_options name: :string
    def snapshot(action)
      do_snapshot(action)
    end

    no_tasks do
      def do_up
        as_virtual do
          vm_names = vm_names!
          raise 'the master must be created before the cluster' if vm_names.size > 1 && vm_names[0] == vm_name && vm_ip!.nil?
          Parallel.each(vm_names, in_threads: Float::INFINITY) do |name, i|
            case vm_state i
            when :null
              add_virtual_host i do
                if i == 0
                  compile_cloud_init
                  add_master_ip do |bridge|
                    system! "multipass launch #{sun.os_version} --name #{name} #{vm_options} --network name=#{bridge},mode=manual"
                  end
                else
                  system! "multipass clone #{vm_name} && multipass start #{name}"
                  add_cluster_ip i
                end
                system! "multipass stop #{name} && multipass start #{name}"
              end
            when :stopped
              system! "multipass start #{name}"
            end
          end
        end
      end

      def do_halt
        as_virtual do
          Parallel.each(vm_names, in_threads: Float::INFINITY) do |name, i|
            case vm_state i
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
          network = vm_ip(0)&.sub(/\.\d+$/, '')
          Parallel.each(vm_names, in_threads: Float::INFINITY) do |name, i|
            cmd = case vm_state i
            when :null
              return
            when :deleted
              "multipass purge"
            when :stopped
              "multipass delete #{name} && multipass purge"
            when :running
              "multipass stop #{name} --force && multipass delete #{name} && multipass purge"
            else
              raise "vm state [#{vm_state i}]"
            end
            remove_virtual_host i do
              system! cmd
              remove_bridge network if i == 0
            end
          end
        end
      end

      def do_status
        as_virtual do
          vm_names.each do |name, i|
            puts "---------------- #{i}"
            system "multipass info #{name}"
          end
        end
      end

      def do_resize
        as_virtual do
          Parallel.each(vm_names, in_threads: Float::INFINITY) do |name, i|
            stopped = false
            case vm_state i
            when :running
              stopped = true
              system! "multipass stop #{name}"
            when :stopped
              # do nothing
            else
              raise "vm state [#{vm_state i}]"
            end
            system! "multipass set local.#{name}.cpus=#{sun.vm_cpu}"   if sun.cpu
            system! "multipass set local.#{name}.memory=#{sun.vm_ram}" if sun.ram
            system! "multipass set local.#{name}.disk=#{sun.vm_disk}"  if sun.disk # NOTE can only be increased
            system! "multipass start #{name}" if stopped
          end
        end
        puts "if the disk is not automatically expanded, then run: 'sudo parted /dev/sda resizepart 1 100%'" if sun.disk
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

      def do_add_ssh
        as_virtual do
          if (web_tools = Gem.root('web_tools'))
            unless (public_key = MULTIPASS_KEY.sub_ext('.pub')).exist?
              copy_file web_tools.join(MULTIPASS_DIR, public_key.basename), public_key, mode: :preserve
            end
            unless MULTIPASS_KEY.exist?
              copy_file web_tools.join(MULTIPASS_DIR, MULTIPASS_KEY.basename), MULTIPASS_KEY, mode: :preserve
            end
          end
          exec "ssh-add #{MULTIPASS_KEY} 2> /dev/null"
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
        raise 'Snapshot name required' unless sun.name.present?
        name = "--name #{@vm_base = vm_snapshot sun.name} --comment #{Time.now.iso8601}"
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
        if (@vm_base = vm_snapshot sun.name).present?
          raise "No snapshot [#{@vm_base}]" unless vm_snapshots.has_key? @vm_base
        else
          @vm_base = vm_snapshots.sort_by{ |_name, info| info[:created] }.last.first
        end
        name = @vm_base
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
        yml[:ssh_authorized_keys] = keys | Setting.authorized_keys | [MULTIPASS_KEY.sub_ext('.pub').read.strip]
        yml[:manage_etc_hosts] = false unless yml.has_key? :manage_etc_hosts
        Pathname.new(TMP_CLOUD_INIT).write(yml.to_hash.pretty_yaml)
      end

      def add_master_ip
        network = free_network
        bridge = "br-#{network.parameterize}"
        system! "nmcli connection add type bridge con-name #{bridge} ifname #{bridge} ipv4.method manual ipv4.addresses #{network}.1/24"
        yield bridge
        add_static_ip 0, network
      end

      def add_cluster_ip(i)
        network = vm_ip(0).sub(/\.\d+$/, '')
        add_static_ip i, network
      end

      def add_static_ip(i, network)
        macs = `multipass exec #{vm_name i} -- ip link`.lines.each_with_object([]) do |line, result|
          case line
          when /^\d+: ([^:]+)/
            result.pop if result.last&.size == 1
            result << [$1]
          when %r{link/\w+ ([^ ]+)}
            result.last << $1
          end
        end.to_h
        raise "no interface ens4: [#{macs.keys.join(', ')}]" unless (mac = macs['ens4'])
        ip = free_ip(network)
        system! "multipass exec -n #{vm_name i} -- sudo bash -c 'cat << EOF > /etc/netplan/10-custom.yaml\n#{<<~YAML}"
          network:
            version: 2
            ethernets:
              ens4:
                dhcp4: no
                match:
                  macaddress: "#{mac}"
                addresses: [#{ip}/24]
          EOF'
        YAML
        system! "multipass exec -n #{vm_name i} -- sudo chmod 600 /etc/netplan/10-custom.yaml && sudo netplan apply"
      end

      def remove_bridge(network)
        system! "nmcli connection delete br-#{network.parameterize}"
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

      def vm_server_host(i = nil)
        name = sun.server_host
        return name if (i ||= sun.i).nil? || i == 0
        "cluster-#{i}.#{name}"
      end

      def vm_name(i = nil)
        name = "vm-#{sun.app.dasherize}"
        return name if (i ||= sun.i).nil? || i == 0
        "#{name}-clone#{i}"
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

      def vm_names
        @vm_names ||= begin
          names = vm_info.map{ |name, _| [name, name.split('-clone').last.to_i] }.to_h
          names = names.slice(names.key(sun.i)) if sun.i
          names = names.slice(names.key(0)) if sun.master
          names = names.except(names.key(0)) if sun.cluster
          names
        end
      end

      def vm_names!
        names = ([vm_name] + sun.vm_clusters.times.map{ |i| vm_name(i + 1) }).map.with_index{ |name, i| [name, i] }.to_h
        names = names.slice(names.key(sun.i)) if sun.i
        names = names.slice(names.key(0)) if sun.master
        names = names.except(names.key(0)) if sun.cluster
        names
      end

      def vm_info
        @vm_info ||= vm_info!
      end

      def vm_info!
        @vm_info = nil
        MULTIPASS_DIR.mkdir_p
        info_was = MULTIPASS_INFO.exist? && YAML.safe_load(MULTIPASS_INFO.read) || {}
        info = ([vm_name] + sun.vm_clusters.times.map{ |i| vm_name(i + 1) }).each_with_object({}).with_index do |(name, hash), i|
          next info_was.delete(name) unless (json = `multipass info #{name} --format=json 2>/dev/null`).present?
          next unless (info = JSON.parse(json).dig('info', name)).present?
          ip_was, cpu_was, ram_was, ram_used, disk_was, disk_used, snapshot_was = (info_was[name] || {}).values_at(*MULTIPASS_INFO_KEYS)
          info_was[name] = hash[name] = info
          info_was[name]['ip']        = info.dig('ipv4', -1) || ip_was
          info_was[name]['cpu_count'] = info.delete('cpu_count').presence&.to_i || cpu_was
          info_was[name]['ram_gb']    = ram = info.dig('memory', 'total')&.to_i&.bytes_to_gb || ram_was
          info_was[name]['ram_used']  = ram && (used = info.dig('memory', 'used')&.to_i&.bytes_to_gb) ? (used / ram).round(5) : ram_used
          info_was[name]['disk_gb']   = disk = info.dig('disks', 'sda1', 'total')&.to_i&.bytes_to_gb || disk_was
          info_was[name]['disk_used'] = disk && (used = info.dig('disks', 'sda1', 'used')&.to_i&.bytes_to_gb) ? (used / disk).round(5) : disk_used
          info_was[name]['snapshot']  = @vm_base || snapshot_was || false if i == 0
          info_was[name]['snapshot_count'] = info.delete('snapshot_count').to_i
        end
        MULTIPASS_INFO.write(info_was.to_yaml)
        info.to_hwia
      end

      def free_ip(network)
        ip = nil
        dns = Pathname.new('/etc/hosts').read
        loop do
          ip = "#{network}.#{rand(200..250)}" # cogeco routers use 192.168.100.xxx
          break unless dns.match?(/^#{ip} /) || Kernel.system("ping -c1 -w3 #{ip} > /dev/null 2>&1")
        end
        ip
      end

      def free_network
        require 'socket'
        network = ''
        networks = [''].concat Socket.getifaddrs.map{ |i| i.addr.ip_address.sub(/\.\d+$/, '') if i.addr.ipv4? }.compact
        loop do
          break unless networks.include? network
          network = "192.168.#{rand(4..254)}"
        end
        network
      end

      def free_mac_address
        macs = `ip link`.each_line.with_object([]) do |line, addresses|
          next unless line =~ %r{link/ether ([^ ]+)}
          addresses << $1
        end
        mac = nil
        loop do
          mac = [rand(0..255) & 0b11111100 | 0b00000010] + Array.new(5){ rand(0..255) }
          mac.map!{ |b| "%02x" % b }.join(":")
          break unless macs.include? mac
        end
        mac
      end
    end
  end
end
