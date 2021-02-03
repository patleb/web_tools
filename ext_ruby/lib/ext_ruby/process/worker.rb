module Process
  def self.worker
    @@worker ||= Worker.new(pid)
  end

  class Worker
    include Snapshot
    include MemoizedAt
    extend MemoizedAt

    STAT_COMM = /\([^)]+\)/
    STAT_NAMES = {
      1  => :name,
      2  => :state,
      3  => :ppid,
      13 => :utime,
      14 => :stime,
      15 => :cutime,
      16 => :cstime,
      18 => :nice,
      19 => :threads,
      21 => :start_time,
    }.freeze
    PROCESS_STATES = HashWithIndifferentAccess.new(
      R: :running,
      S: :sleeping,
      D: :disk_sleep,
      T: :stopped,
      t: :tracing_stop,
      X: :dead,
      Z: :zombie,
      P: :parked,
      I: :idle,
    ).freeze
    PID_DEAD = -1
    PID_INIT = 1

    cattr_reader :host, default: Process.host
    attr_reader  :pid

    def self.all(nohup: nil)
      m_access(:all, nohup) do
        host.pids.each_with_object([]) do |pid, memo|
          next if (worker = new(pid)).ppid == PID_DEAD
          next if nohup && worker.ppid != PID_INIT
          memo << worker
        end
      end
    end

    def initialize(pid)
      @pid = pid
    end

    def parent
      self.class.new(ppid)
    end

    def children
      m_access(:children) do
        self.class.all.each_with_object([]) do |worker, memo|
          next if worker.ppid != pid
          memo << child
        end
      end
    end

    def pool
      [self].concat(siblings.select{ |sibling| sibling.name == name })
    end

    def siblings
      m_access(:siblings) do
        self.class.all.each_with_object([]) do |worker, memo|
          next if worker.pid.in? [PID_INIT, pid, ppid]
          if [worker.ppid, ppid].exclude? PID_INIT
            next if worker.ppid != ppid
          else
            next if worker.cmdline != cmdline
          end
          memo << worker
        end
      end
    end

    def name
      @name ||= cpu[:name].to_s
    end

    def ppid
      cpu[:ppid].to_i
    end

    def uptime
      (Time.now - start_time).ceil(3)
    end

    def start_time
      @start_time ||= cpu[:start_time]
    end

    def cpu_usage
      ((cpu[:time] / uptime) / host.cpu_count).ceil(6)
    end

    def cpu
      m_access(:cpu) do
        stat = File.read("/proc/#{@pid}/stat")
        comm = stat[STAT_COMM].delete_prefix('(').delete_suffix(')')
        stat.sub! STAT_COMM, '*'
        stat = stat.split.each_with_object({}).with_index do |(value, memo), i|
          next unless STAT_NAMES.has_key? i
          name = STAT_NAMES[i]
          memo[name] = case name
            when :comm       then comm
            when :state      then PROCESS_STATES[value]
            when :start_time then host.boot_time + (value.to_f / host.hertz)
            when /time$/     then value.to_f
            else                  value.to_i
            end
        end
        time = stat.delete(:utime) + stat.delete(:stime) + stat.delete(:cutime) + stat.delete(:cstime)
        stat[:time] = (time / host.hertz).ceil(3)
        stat
      rescue Errno::ENOENT
        { ppid: PID_DEAD, start_time: -host.hertz }
      end
    end

    def ram_used
      memory_mb[:ram_used]
    end

    def swap_used
      memory_mb[:swap_used]
    end

    def memory_mb
      m_access(:memory) do
        memory = File.readlines("/proc/#{@pid}/smaps_rollup").each_with_object({}) do |line, memo|
          type = case line
            when /^Rss:/  then :ram_used
            when /^Swap:/ then :swap_used
            end
          memo[type] = line.split.second.to_i.kbytes_to_mb if type
        end
        File.readlines("/proc/#{@pid}/io").each_with_object(memory) do |line, memo|
          type = case line
            when /^read_bytes:/  then :total_in
            when /^write_bytes:/ then :total_out
            end
          memo[type] = line.split(': ').last.to_i.bytes_to_mb if type
        end
      rescue Errno::ENOENT
        { ram_used: 0.0, swap_used: 0.0 }
      end
    end

    def inodes_count
      inodes.values.sum(&:size)
    end

    # readable ones only --> use "rbenv sudo ..."
    def inodes
      m_access(:inodes) do
        files = Rake::FileList["/proc/#{@pid}/fd/*"]
        files.each_with_object(socket: [], pipe: [], epoll: [], anon: [], dead_device: [], device: [], dead_file: [], file: []) do |file, memo|
          type = case File.readlink(file)
            when /^socket:/                  then :socket
            when /^pipe:/                    then :pipe
            when /^anon_inode:\[eventpoll\]/ then :epoll
            when /^anon_inode:/              then :anon
            when %r{^/dev/.+\(deleted\)$}    then :dead_device
            when %r{^/dev/}                  then :device
            when /\(deleted\)$/              then :dead_file
            else                                  :file
            end
          memo[type] << File.stat(file).ino
        rescue Errno::ENOENT
          # do nothing
        end
      rescue Errno::ENOENT
        {}
      end
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
      @cmdline ||= File.read("/proc/#{@pid}/cmdline").split("\0") rescue []
    end

    def env
      File.read("/proc/#{@pid}/environ").split("\0").each_with_object({}) do |pair, memo|
        name, value = pair.split('=')
        memo[name] = value
      end
    rescue Errno::ENOENT
      {}
    end
  end
end
