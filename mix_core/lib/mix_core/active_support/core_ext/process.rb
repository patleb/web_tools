# TODO https://github.com/vidibus/vidibus-sysinfo
module Process
  def self.host
    @@host ||= Host.new
  end

  def self.worker
    @@worker ||= Worker.new(pid)
  end

  def self.exist?(pid)
    raise ArgumentError, "Bad type: `Process#exist?` requires pid as Integer." unless pid.is_a? Integer

    File.exist? "/proc/#{pid}"
  end
end
