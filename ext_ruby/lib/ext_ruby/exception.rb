class Exception
  def self.wtf?
    yield
  rescue => e
    puts e.backtrace_log
  end

  def backtrace_log(n = 20)
    log = ["[#{self.class}]"]
    log << message if message != self.class.to_s
    log.concat((backtrace || []).first(n)).join("\n")
  end
end

def wtf(&block)
  Exception.wtf?(&block)
end
