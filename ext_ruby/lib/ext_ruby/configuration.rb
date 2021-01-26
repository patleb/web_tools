module ExtRuby
  has_config do
    attr_writer :memoized_at_threshold
    attr_writer :cpu_load_threshold
    attr_writer :host_snapshot
    attr_writer :worker_snapshot

    def memoized_at_threshold
      @memoized_at_threshold ||= 5.0
    end

    def cpu_load_threshold
      @cpu_load_threshold ||= 0.7
    end

    def host_snapshot
      @host_snapshot ||= %i(
        cpu
        memory_gb
        disks_gb
        network
        sockets
      )
    end

    def worker_snapshot
      @worker_snapshot ||= %i(
        cpu
        memory_mb
        inodes
      )
    end
  end
end
