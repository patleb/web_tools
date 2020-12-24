# TODO add io bandwidth / number of connections

module Process
  class Host
    include Snapshot
    include MemoizedAt

    STAT_NAMES = %i(
      user
      nice
      system
      idle
      iowait
      irq
      softirq
      steal
      guest
      guest_nice
    ).freeze
    SWAP_NAMES = %i(
      filename
      type
      size
      used
      priority
    ).freeze
    RISKY_LOAD_AVG = 0.7
    SNAPSHOT = %i(
      name
      private_ip
      boot_time
      uptime
      cpu_count
      cpu_usage
      cpu_load
      ram_total_mb
      ram_used_mb
      swap_total_mb
      swap_used_mb
      fs_total_mb
      fs_used_mb
    ).freeze
    SNAPSHOT_DIFF = %i(
      uptime
      cpu_usage
      cpu_load
      ram_used_mb
      swap_used_mb
      fs_used_mb
    ).freeze

    delegate :cpu, :memory, :disk, :load_average, to: :Vmstat

    def name
      @name ||= Socket.gethostname
    end

    def private_ip
      @private_ip ||= Socket.ip_address_list.reverse.find{ |addrinfo| addrinfo.ipv4_private? }.ip_address
    end

    def boot_time
      @boot_time ||= Time.now - IO.read("/proc/uptime").split.first.to_f
    end

    def uptime
      (Time.now - boot_time).ceil(3)
    end

    def cpu_count
      @cpu_count ||= cpu.size
    end

    def cpu_usage
      working = stat.values_at(:user, :system).sum(&:to_i)
      (working / (working + stat[:idle].to_f)).ceil(6)
    end

    def cpu_load
      m_access(:load_average){ load_average.to_a.map{ |avg| avg / cpu_count } }
    end

    def cpu_load_high?
      cpu_load.any?{ |avg| avg > RISKY_LOAD_AVG }
    end

    def cpu_load_increasing?
      min_1, min_5, min_15 = cpu_load
      (min_1 > min_5) && (min_1 > min_15)
    end

    def cpu_load_decreasing?
      min_1, min_5, min_15 = cpu_load
      (min_1 < min_5) || (min_1 < min_15)
    end

    def ram_available_mb
      m_access(:memory).available_bytes.bytes_to_mb.to_f.floor(3)
    end

    def ram_total_mb
      m_access(:memory).total_bytes.bytes_to_mb.to_f.ceil(3)
    end

    def ram_used_mb
      (ram_total_mb - ram_available_mb).ceil(3)
    end

    def swap_available_mb
      (swap_total_mb - swap_used_mb).floor(3)
    end

    def swap_total_mb
      BigDecimal(swap[:size]).kbytes_to_mb.to_f.ceil(3)
    end

    def swap_used_mb
      BigDecimal(swap[:used]).kbytes_to_mb.to_f.ceil(3)
    end

    def fs_available_mb
      m_access(:disk, "/").available_bytes.bytes_to_mb.to_f.floor
    end

    def fs_total_mb
      m_access(:disk, "/").total_bytes.bytes_to_mb.to_f.ceil
    end

    def fs_used_mb
      (fs_total_mb - fs_available_mb).ceil
    end

    def pagesize
      @pagesize ||= Vmstat.pagesize
    end

    def hertz
      @hertz ||= Process.clock_getres(:TIMES_BASED_CLOCK_PROCESS_CPUTIME_ID, :hertz)
    end

    def swap
      m_access(:swap) do
        swap = IO.read("/proc/swaps").lines(chomp: true).second
        swap.split.each_with_object({}).with_index do |(value, memo), index|
          memo[SWAP_NAMES[index]] = value
        end
      end
    end

    def stat
      m_access(:stat) do
        stat = IO.read("/proc/stat").lines(chomp: true).first
        stat = stat.sub(/^cpu +/, '')
        stat.split.each_with_object({}).with_index do |(value, memo), index|
          memo[STAT_NAMES[index]] = value
        end
      end
    end
  end
end
