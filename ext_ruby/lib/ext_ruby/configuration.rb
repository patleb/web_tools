module ExtRuby
  has_config do
    attr_writer :backtrace_log_lines
    attr_writer :memoized_at_timeout
    attr_writer :host_disk_partition
    attr_writer :host_snapshot
    attr_writer :worker_snapshot

    def backtrace_log_lines
      @backtrace_log_lines ||= 20
    end

    def memoized_at_timeout
      @memoized_at_timeout ||= 20.0
    end

    def host_disk_partition
      @host_disk_partition ||= '/dev/sda'
    end

    def host_snapshot
      @host_snapshot ||= %i(
        boot_time
        cpu_load
        cpu_pids
        cpu_work
        cpu_idle
        cpu_steal
        memory
        disks
        network
      )
    end

    def worker_snapshot
      @worker_snapshot ||= %i(
        cpu
        memory
      )
    end
  end
end
