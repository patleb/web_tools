module Sunzistrano
  MULTIPASS_DIR  = Pathname.new('.multipass')
  MULTIPASS_KEY  = MULTIPASS_DIR.join('key')
  MULTIPASS_INFO = MULTIPASS_DIR.join('info.yml')
  MULTIPASS_INFO_KEYS = %w(ip ip_was cpu_count ram_gb ram_used disk_gb disk_used snapshot)
  MULTIPASS_MOUNT  = '/opt/multipass'
  ERB_CLOUD_INIT   = Pathname.new('./cloud-init.yml')
  TMP_CLOUD_INIT   = Pathname.new('./tmp/cloud-init.yml')
  SNAPSHOT_ACTIONS = %w(save restore list delete)

  Cli.class_eval do
    desc 'up [-i] [--master] [--cluster] [--clone] [--static-ip]', 'Start Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false, clone: false, static_ip: false
    def up = do_up

    desc 'halt [-i] [--master] [--cluster] [--force]', 'Stop Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false, force: false
    def halt = do_halt

    desc 'destroy [-i] [--master] [--cluster]', 'Delete Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false
    def destroy = do_destroy

    desc 'status [-i] [--master] [--cluster]', 'Output status of Multipass instance(s)'
    method_options i: :numeric, master: false, cluster: false
    def status = do_status

    desc 'resize [--cpu] [--ram] [--disk]', 'Resize Multipass instance(s)'
    method_options cpu: false, ram: false, disk: false
    def resize = do_resize

    desc 'mount [--src] [--dst] [--deploy]', "Mount Multipass instance directory (#{MULTIPASS_MOUNT} or :dst)"
    method_options src: :string, dst: :string, deploy: false
    def mount = do_mount

    desc 'unmount [--dst]', "Unmount Multipass instance directory (#{MULTIPASS_MOUNT} or :dst)"
    method_options dst: :string
    def unmount = do_unmount

    desc 'ssh [-i] [-c]', 'Shell into Multipass instance (or execute -c command)'
    method_options i: :numeric, c: :string
    def ssh = do_ssh

    desc 'ssh-add', 'Add Multipass ssh private key'
    def ssh_add = do_add_ssh

    desc 'snapshot [ACTION] [-i] [--master] [--cluster] [--name]', "#{SNAPSHOT_ACTIONS.map(&:upcase_first).join('/')} Multipass master's snapshot(s)"
    method_options i: :numeric, master: false, cluster: false, name: :string
    def snapshot(action) = do_snapshot(action)

    no_tasks do
      def do_up
        as_virtual do
          vm_names = vm_names!
          if (sun.clone || sun.static_ip) && vm_names.size > 1 && vm_names[vm_name] == 0 && vm_ip(0).nil?
            raise 'the master must be created before the cluster'
          end
          vm_names.each do |name, i|
            case vm_state i
            when :null
              add_virtual_host i do
                if i == 0
                  compile_cloud_init
                  add_static_ip 0 do |network|
                    system! "multipass launch #{sun.os_version} --name #{name} #{vm_options} #{network}"
                  end
                elsif sun.clone
                  add_static_ip i do
                    system! "multipass clone #{vm_name} --name #{name} && multipass start #{name}"
                  end
                else
                  add_static_ip i do |network|
                    system! "multipass launch #{sun.os_version} --name #{name} #{vm_options} #{network}"
                  end
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
          vm_names.each do |name, i|
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
          vm_names.each do |name, i|
            remove_virtual_host i do
              case vm_state i
              when :null
                return
              when :deleted
                system! "multipass purge"
              when :stopped
                system! "multipass delete #{name} && multipass purge"
              when :running
                system! "multipass stop #{name} --force && multipass delete #{name} && multipass purge"
              else
                raise "vm state [#{vm_state i}]"
              end
              remove_bridge network if i == 0
            end
          end
        end
      end

      def do_status
        as_virtual do
          vm_names.each do |name, i|
            puts "--------------- #{i}"
            system "multipass info #{name}"
          end
        end
      end

      def do_resize
        as_virtual do
          vm_names.each do |name, i|
            running = false
            case vm_state i
            when :running
              running = true
              system! "multipass stop #{name}"
            when :stopped
              # do nothing
            else
              raise "vm state [#{vm_state i}]"
            end
            system! "multipass set local.#{name}.cpus=#{sun.vm_cpu}"   if sun.cpu
            system! "multipass set local.#{name}.memory=#{sun.vm_ram}" if sun.ram
            system! "multipass set local.#{name}.disk=#{sun.vm_disk}"  if sun.disk # NOTE can only be increased
            system! "multipass start #{name}" if running
          end
        end
        puts "if the disk is not automatically expanded, then run: 'sudo parted /dev/sda resizepart 1 100%'" if sun.disk
      end

      def do_mount
        as_virtual do
          dst = sun.dst || MULTIPASS_MOUNT
          return unless vm_info.dig(vm_name, :mounts, dst).nil?
          src = sun.src || MULTIPASS_DIR.join(vm_name)
          owner = "-g #{File.stat(Dir.pwd).gid}:#{sun.deployer_id} -u #{File.stat(Dir.pwd).uid}:#{sun.deployer_id}" if sun.deploy
          mount_dir = Pathname.new(src)
          mount_dir.mkdir_p
          mount_cmd = "multipass mount --type=native #{mount_dir} #{vm_name}:#{dst} #{owner}"
          case vm_state
          when :stopped
            system! mount_cmd
          when :running
            system! "multipass stop #{vm_name} && #{mount_cmd} && multipass start #{vm_name}"
          else
            raise "vm state [#{vm_state}]"
          end
        end
      end

      def do_unmount
        as_virtual do
          dst = sun.dst || MULTIPASS_MOUNT
          return if vm_info.dig(vm_name, :mounts, dst).nil?
          system! "multipass umount #{vm_name}:#{dst}"
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
          @vm_base = {}
          vm_names.each do |name, i|
            send "run_snapshot_#{action}_cmd", name, i
          end
        end
      end

      private

      def as_virtual(&block)
        with_context 'virtual', :provision, &block
        vm_info!
      end

      def run_snapshot_save_cmd(name, i)
        raise 'Snapshot name required' unless sun.name.present?
        snapshot = "--name #{@vm_base[name] = vm_snapshot sun.name} --comment #{Time.now.iso8601}"
        case vm_state i
        when :stopped
          system! "multipass snapshot #{snapshot} #{name}"
        when :running
          system! "multipass stop #{name} && multipass snapshot #{snapshot} #{name} && multipass start #{name}"
        else
          raise "vm state [#{vm_state i}]"
        end
      end

      def run_snapshot_restore_cmd(name, i)
        raise 'No snapshots' unless (snapshots = vm_snapshots[name])
        if (snapshot = (@vm_base[name] = vm_snapshot sun.name)).present?
          raise "No snapshot [#{snapshot}]" unless snapshots.has_key? snapshot
        else
          snapshot = @vm_base[name] = snapshots.sort_by{ |_name, info| info[:created] }.last.first
        end
        case vm_state i
        when :stopped
          system! "multipass restore #{name}.#{snapshot} --destructive"
        when :running
          system! "multipass stop #{name} && multipass restore #{name}.#{snapshot} --destructive && multipass start #{name}"
        else
          raise "vm state [#{vm_state i}]"
        end
      end

      def run_snapshot_list_cmd(name, i)
        system "multipass list --snapshots | grep -E '^(Instance|#{name}) '"
      end

      def run_snapshot_delete_cmd(name, i)
        raise 'Snapshot name required' unless (snapshot = vm_snapshot sun.name)
        raise "No snapshot [#{snapshot}]" unless (snapshots = vm_snapshots[name])&.has_key? snapshot
        case vm_state i
        when :stopped
          system! "multipass delete #{name}.#{snapshot} --purge"
        when :running
          system! "multipass stop #{name} && multipass delete #{name}.#{snapshot} --purge"
        else
          raise "vm state [#{vm_state i}]"
        end
      end

      def vm_snapshots
        @vm_snapshots ||= if (json = `multipass list --snapshots --format=json`).present?
          hash = JSON.parse(json)['info']
          vm_list.each_with_object({}) do |name, snapshots|
            snapshots[name] = (hash[name] || {}).each_with_object({}) do |(snapshot, _info), memo|
              snapshot = vm_snapshot(snapshot)
              json = `multipass info #{name}.#{snapshot} --format=json`
              info = JSON.parse(json).dig('info', name, 'snapshots', snapshot)
              info['created'] = Time.parse(info['created']).in_time_zone('UTC')
              memo[snapshot] = info.to_hwka
            end
          end
        else
          {}
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
        if ERB_CLOUD_INIT.exist?
          yml = YAML.safe_load(ERB.template(ERB_CLOUD_INIT, binding)).to_hwia
        else
          yml = {}
        end
        keys = Array.wrap(yml[:ssh_authorized_keys])
        yml[:ssh_authorized_keys] = keys | Setting.authorized_keys | [MULTIPASS_KEY.sub_ext('.pub').read.strip]
        yml[:manage_etc_hosts] = false unless yml.has_key? :manage_etc_hosts
        TMP_CLOUD_INIT.write(yml.to_hash.pretty_yaml)
      end

      def add_static_ip(i)
        return yield unless sun.static_ip
        network = (i == 0) ? free_network : vm_ip(0).sub(/\.\d+$/, '')
        bridge = "br-#{network.parameterize}"
        if i == 0
          system! "nmcli connection add type bridge con-name #{bridge} ifname #{bridge} ipv4.method manual ipv4.addresses #{network}.1/24"
        end
        yield "--network name=#{bridge},mode=manual"
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
        ip, name = free_ip(network), vm_name(i)
        system! "multipass exec -n #{name} -- sudo bash -c 'cat << EOF > /etc/netplan/10-custom.yaml\n#{<<~YAML}"
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
        system! "multipass exec -n #{name} -- sudo chmod 600 /etc/netplan/10-custom.yaml && sudo netplan apply"
        system! "multipass stop #{name} && multipass start #{name}"
      end

      def remove_bridge(network)
        return unless network.start_with? '192.168.'
        system! "nmcli connection delete br-#{network.parameterize}"
      end

      def add_virtual_host(*)
        ip_was = vm_ip(*)
        yield
        ip = vm_ip!(*)
        if ip_was != ip
          if ip_was.nil?
            puts "IP '#{ip}' successfully added#{' [STATIC]' if sun.static_ip}.".green
          else
            puts "IP has changed '#{ip_was}' --> '#{ip}'.".red
          end
        end
        system! Sh.delete_lines!('/etc/hosts', /[^\d]#{ip}[^\d]/, sudo: true) if ip_was
        system! Sh.append_host("#{Host::VIRTUAL}-#{ip}", ip, vm_server_host(*))
      end

      def remove_virtual_host(*)
        ip_was = vm_ip(*)
        yield
        if (ip = vm_ip!(*)) && ip_was != ip
          puts "IP has changed '#{ip_was}' --> '#{ip}'.".red
        end
        [ip_was, ip].each do |ip|
          system! Sh.delete_lines!('/etc/hosts', /[^\d]#{ip}[^\d]/, sudo: true) if ip
        end
      end

      def vm_server_host(i = nil)
        name = sun.server_host
        return name if (i ||= sun.i).nil? || i == 0
        "#{Setting[:cloud_cluster_name]}-#{i}.#{name}"
      end

      def vm_name(i = nil)
        name = "vm-#{sun.app.dasherize}"
        return name if (i ||= sun.i).nil? || i == 0
        "#{name}-#{Setting[:cloud_cluster_name]}-#{i}"
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
          names = vm_info.map{ |name, _| [name, name.split("-#{Setting[:cloud_cluster_name]}-").last.to_i] }.to_h
          names = names.slice(names.key(sun.i)) if sun.i
          names = names.slice(names.key(0)) if sun.master
          names = names.except(names.key(0)) if sun.cluster
          names
        end
      end

      def vm_names!
        names = vm_list.map.with_index{ |name, i| [name, i] }.to_h
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
        info = vm_list.each_with_object({}) do |name, hash|
          next info_was.delete(name) unless (json = `multipass info #{name} --format=json 2>/dev/null`).present?
          next unless (info = JSON.parse(json).dig('info', name)).present?
          ip, ip_was, cpu, ram_was, ram_used, disk_was, disk_used, snapshot = (info_was[name] || {}).values_at(*MULTIPASS_INFO_KEYS)
          info['ip']        = info.dig('ipv4', -1) || ip
          info['ip_was']    = info.dig('ipv4',  0) || ip_was
          info['cpu_count'] = info.delete('cpu_count').presence&.to_i || cpu
          info['ram_gb']    = ram = info.dig('memory', 'total')&.to_i&.bytes_to_gb || ram_was
          info['ram_used']  = ram && (used = info.dig('memory', 'used')&.to_i&.bytes_to_gb) ? (used / ram).round(5) : ram_used
          info['disk_gb']   = disk = info.dig('disks', 'sda1', 'total')&.to_i&.bytes_to_gb || disk_was
          info['disk_used'] = disk && (used = info.dig('disks', 'sda1', 'used')&.to_i&.bytes_to_gb) ? (used / disk).round(5) : disk_used
          info['snapshot']  = @vm_base&.dig(name) || snapshot || false
          info['snapshot_count'] = info.delete('snapshot_count').to_i
          info_was[name] = hash[name] = info
        end
        MULTIPASS_INFO.write(info_was.to_yaml)
        info.to_hwia
      end

      def vm_list
        @vm_list ||= ([vm_name] + sun.vm_clusters.times.map{ |i| vm_name(i + 1) })
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
