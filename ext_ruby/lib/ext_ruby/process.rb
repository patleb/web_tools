module Process
  def self.exist?(pid)
    raise ArgumentError, "Bad type: `Process#exist?` requires pid as Integer." unless pid.is_a? Integer

    File.exist? "/proc/#{pid}"
  end
end
