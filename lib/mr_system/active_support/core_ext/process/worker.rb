module Process
  class Worker
    include Snapshot
    include MemoizedAt
    extend MemoizedAt

    STAT_NAMES = %i(
      pid
      comm
      state
      ppid
      pgrp
      session
      tty_nr
      tpgid
      flags
      minflt
      cminflt
      majflt
      cmajflt
      utime
      stime
      cutime
      cstime
      priority
      nice
      num_threads
      itrealvalue
      starttime
      vsize
      rss
      rsslim
      startcode
      endcode
      startstack
      kstkesp
      kstkeip
      signal
      blocked
      sigignore
      sigcatch
      wchan
      nswap
      cnswap
      exit_signal
      processor
      rt_priority
      policy
      delayacct_blkio_ticks
      guest_time
      cguest_time
      start_data
      end_data
      start_brk
      arg_start
      arg_end
      env_start
      env_end
      exit_code
    ).freeze
    PID = IceNine.deep_freeze(
      dead: -1,
      none: 0,
      init: 1,
    )
    SNAPSHOT = %i(
      name
      pid
      ppid
      start_time
      uptime
      cpu_usage
      ram_used_mb
    ).freeze
    SNAPSHOT_DIFF = %i(
      uptime
      cpu_usage
      ram_used_mb
    ).freeze

    cattr_reader :host do
      Process.host
    end
    attr_reader :pid

    def self.all(nohup: false)
      m_access(:all, (:nohup if nohup), threshold: 1.0) do
        Dir.foreach("/proc").each_with_object([]) do |file, result|
          worker = new(file.to_i)
          next if worker.ppid == PID[:dead]
          next if nohup && worker.ppid != PID[:init]
          result << worker
        end
      end
    end

    def initialize(pid)
      @pid = pid
    end

    def parent
      self.class.new(ppid)
    end

    def self_and_siblings
      [self].concat siblings
    end

    def siblings
      m_access(:siblings, threshold: 1.0) do
        Dir.foreach("/proc").each_with_object([]) do |file, result|
          next if (sibling_pid = file.to_i).in? [PID[:none], PID[:init], pid, ppid]
          if [(sibling = self.class.new(sibling_pid)).ppid, ppid].exclude? PID[:init]
            next if sibling.ppid != ppid
          else
            next if sibling.cmdline != cmdline
          end
          result << sibling
        end
      end
    end

    def name
      @name ||= stat[:comm].to_s
    end

    def ppid
      stat[:ppid].to_i
    end

    def start_time
      host.boot_time + (stat[:starttime].to_f / host.hertz)
    end

    def uptime
      (Time.current - start_time).ceil(3)
    end

    def cpu_usage
      working = stat.values_at(:utime, :stime, :cutime, :cstime).sum(&:to_i) / host.hertz
      ((working / (Time.current - start_time)) / host.cpu_count).ceil(6)
    end

    def ram_used_mb
      (BigDecimal(stat[:rss]) * host.pagesize).bytes_to_mb.to_f.ceil(3)
    end

    def cwd
      @cwd ||= File.readlink("/proc/#{@pid}/cwd") rescue ''
    end

    def exe
      @exe ||= File.readlink("/proc/#{@pid}/exe") rescue ''
    end

    def root
      @root ||= File.readlink("/proc/#{@pid}/root") rescue ''
    end

    def cmdline
      @cmdline ||= IO.read("/proc/#{@pid}/cmdline").split("\0") rescue []
    end

    def env
      IO.read("/proc/#{@pid}/environ").split("\0").each_with_object({}) do |pair, memo|
        name, value = pair.split('=')
        memo[name] = value
      end
    rescue
      {}
    end

    def stat
      m_access(:stat) do
        stat = IO.read("/proc/#{@pid}/stat")
        stat.gsub!(/\([^\)]+\)/){ |match| match.tr(' ', '-').gsub(/^\(|\)$/, '') }
        stat.split.each_with_object({}).with_index do |(value, memo), index|
          memo[STAT_NAMES[index]] = value
        end
      end
    rescue
      {
        ppid: PID[:dead],
        starttime: -host.hertz,
        rss: BigDecimal(0),
      }
    end
  end
end
