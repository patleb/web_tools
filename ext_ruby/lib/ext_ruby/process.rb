module Process
  def self.exist?(pid)
    raise ArgumentError, "Bad type: `Process#exist?` requires pid as Integer." unless pid.is_a? Integer
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end
end
