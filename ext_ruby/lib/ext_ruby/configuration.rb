module ExtRuby
  has_config do
    attr_writer :memoized_at_threshold
    attr_writer :host_snapshot
    attr_writer :worker_snapshot

    def memoized_at_threshold
      @memoized_at_threshold ||= 20.0
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
