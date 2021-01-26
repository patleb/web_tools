### References
# https://stackoverflow.com/questions/23367857/accurate-calculation-of-cpu-usage-given-in-percentage-in-linux
# https://www.kernel.org/doc/html/latest/block/stat.html
module Process
  def self.host
    @@host ||= Host.new
  end

  class Host
    include Snapshot
    include MemoizedAt

    TIMES = %i(
      user
      nice
      system
      idle
      iowait
      irq
      softirq
      steal
    ).freeze
    WORK_TIMES = %i(
      user
      nice
      system
      irq
      softirq
    ).freeze
    IDLE_TIMES = %i(
      idle
      iowait
    ).freeze
    SOCKET_STATES = %i(
      undefined
      established
      syn_sent
      syn_recv
      fin_wait_1
      fin_wait_2
      time_wait
      close
      close_wait
      last_ack
      listen
      closing
      new_syn_recv
    ).freeze
    DISK_READS        = 2
    DISK_WRITES       = 6
    DISK_IO_TICKS     = 9 # doesn't include time between system calls
    BYTES_PER_SECTOR  = 512
    NETWORK_BYTES_IN  = 0
    NETWORK_BYTES_OUT = 8
    RESERVED_INODES   = 12

    delegate :disk, :load_average, to: :Vmstat

    def workers(nohup: nil)
      Process::Worker.all(nohup: nohup)
    end

    def name
      @name ||= Socket.gethostname
    end

    def private_ip
      @private_ip ||= Socket.ip_address_list.reverse.find{ |addrinfo| addrinfo.ipv4_private? }.ip_address
    end

    def processes
      cpu[:pids]
    end

    def uptime
      (Time.now - boot_time).ceil(3)
    end

    def boot_time
      @boot_time ||= cpu[:boot]
    end

    def cpu_count
      @cpu_count ||= cpu[:size]
    end

    def cpu_usage
      return 0.0 if (total = cpu_total).zero?
      (cpu_work / total).ceil(6)
    end

    def cpu_total
      cpu_work + cpu_idle + cpu_steal
    end

    def cpu_work
      time = cpu.values_at(*WORK_TIMES).sum
      time -= snapshot[:cpu].values_at(*WORK_TIMES).sum if snapshot?
      time / (hertz * cpu_count)
    end

    def cpu_idle
      time = cpu.values_at(*IDLE_TIMES).sum
      time -= snapshot[:cpu].values_at(*IDLE_TIMES).sum if snapshot?
      time / (hertz * cpu_count)
    end

    # https://scoutapm.com/blog/understanding-cpu-steal-time-when-should-you-be-worried
    def cpu_steal
      time = cpu[:steal]
      time -= snapshot.dig(:cpu, :steal) if snapshot?
      time / (hertz * cpu_count)
    end

    def cpu_load
      m_access(:load_average){ load_average.to_a.map{ |avg| avg / cpu_count } }
    end

    def cpu_load_high?
      cpu_load.any?{ |avg| avg > ExtRuby.config.cpu_load_threshold }
    end

    def cpu_load_increasing?
      min_1, min_5, min_15 = cpu_load
      (min_1 > min_5) && (min_1 > min_15)
    end

    def cpu_load_decreasing?
      min_1, min_5, min_15 = cpu_load
      (min_1 < min_5) || (min_1 < min_15)
    end

    def cpu
      m_access(:cpu) do
        File.readlines("/proc/stat").each_with_object(size: 0) do |line, memo|
          case line
          when /^cpu /      then line.split(' ', TIMES.size + 1).drop(1).each_with_index{ |v, i| memo[TIMES[i]] = v.to_i }
          when /^cpu\d+/    then memo[:size] = @cpu_count ? @cpu_count : memo[:size] + 1
          when /^btime/     then memo[:boot] = @boot_time ? @boot_time : Time.at(line.split.last.to_i)
          when /^processes/ then memo[:pids] = line.split.last.to_i
          end
        end
      end
    end

    def ram_usage
      (ram_used / ram_total).ceil(3)
    end

    def ram_total
      memory_gb[:ram_total]
    end

    def ram_used
      memory_gb[:ram_used]
    end

    def swap_usage
      (swap_used / swap_total).ceil(3)
    end

    def swap_total
      memory_gb[:swap_total]
    end

    def swap_used
      memory_gb[:swap_used]
    end

    def memory_gb
      m_access(:memory) do
        memory = File.readlines("/proc/meminfo").each_with_object({}) do |line, memo|
          type = case line
            when /^MemTotal:/     then :ram_total
            when /^MemAvailable:/ then :ram_free
            when /^SwapTotal:/    then :swap_total
            when /^SwapFree:/     then :swap_free
            end
          memo[type] = line.split.second.to_i if type
        end
        memory[:ram_used] = memory[:ram_total] - memory.delete(:ram_free)
        memory[:swap_used] = memory[:swap_total] - memory.delete(:swap_free)
        memory.transform_values!(&:kbytes_to_gb)
        File.readlines("/proc/vmstat").each_with_object(memory) do |line, memo|
          type = case line
            when /^pgpgin /  then :ram_in
            when /^pgpgout / then :ram_out
            when /^pswpin /  then :swap_in
            when /^pswpout / then :swap_out
            end
          memo[type] = (line.split.second.to_i * pagesize).bytes_to_gb if type
        end
      end
    end

    def disks_gb
      m_access(:disks) do
        File.readlines("/proc/diskstats").each_with_object({}) do |line, memo|
          fields = line.split.drop(2)
          name = fields.shift
          next unless mounts.has_key? name
          reads, writes, io_ticks = fields.values_at(DISK_READS, DISK_WRITES, DISK_IO_TICKS).map(&:to_i)
          path = mounts[name]
          disk = disk(path)
          memo[path] = {
            fs_total: disk.total_bytes.bytes_to_gb,
            fs_used: (disk.total_bytes - disk.available_bytes).bytes_to_gb,
            io_size: [reads, writes].map{ |v| (v * BYTES_PER_SECTOR).bytes_to_gb },
            io_time: (io_ticks / 1000.0).ceil(3)
          }
        end
      end
    end

    def network_usage
      snapshot ? network.map.with_index{ |value, i| (value - snapshot.dig(:network, i)).ceil(6) } : network
    end

    def network
      networks_mb.find{ |k, _| k.start_with? 'en', 'eth', 'wl' }.last
    end

    def networks_mb
      m_access(:networks) do
        File.readlines("/proc/net/dev").drop(2)
          .map{ |line| line.split(':') }.to_h
          .transform_values{ |v| v.split.values_at(NETWORK_BYTES_IN, NETWORK_BYTES_OUT).map(&:to_i) }
          .reject{ |_, v| v.all?(&:zero?) }
          .transform_values{ |v| v.map{ |bytes| bytes.bytes_to_mb } }
          .transform_keys(&:squish)
      end
    end

    def sockets(pid: true, worker: false)
      if pid || worker
        pids = inodes.slice(*sockets(pid: false).keys).each_with_object({}) do |(inode, pid), memo|
          memo[pid] = sockets(pid: false)[inode]
        end
        return worker ? pids.transform_keys{ |pid| Process::Worker.new(pid) } : pids
      end
      m_access(:sockets) do
        %i(tcp udp).each_with_object({}) do |type, memo|
          File.readlines("/proc/net/#{type}").drop(1).each_with_index do |line, i|
            _, local, remote, state, _, _, _, _, _, inode, *_rest = line.split
            inode = -i if (inode = inode.to_i) < RESERVED_INODES
            memo[inode] = [type] + [local, remote].flat_map do |address|
              ip, port = address.split(':')
              [ip.chars.each_slice(2).map(&:join).map(&:to_i.with(16)).reverse.join('.'), port.to_i(16)]
            end << SOCKET_STATES[state.to_i(16)]
          end
        end
      end
    end

    def mounts
      @mounts ||= File.readlines("/proc/mounts").each_with_object({}) do |line, memo|
        next unless line.start_with? '/dev/'
        dev, mount, _ = line.split(' ', 3)
        next if mount.start_with? '/boot/', '/media/'
        memo[dev.delete_prefix('/dev/')] = mount
      end
    end

    def pids
      m_access(:pids) do
        Rake::FileList["/proc/*"].map{ |file| File.basename(file).to_i }.reject(&:zero?)
      end
    end

    def inodes_count
      inodes.size
    end

    def inodes
      m_access(:inodes) do
        workers.each_with_object({}) do |worker, memo|
          pid = worker.pid
          worker.inodes.values.map{ |inodes| Set.new(inodes) }.reduce(&:merge).each{ |inode| memo[inode] = pid }
        end
      end
    end

    def pagesize
      @pagesize ||= Vmstat.pagesize
    end

    def hertz
      @hertz ||= Process.clock_getres(:TIMES_BASED_CLOCK_PROCESS_CPUTIME_ID, :hertz)
    end
  end
end
