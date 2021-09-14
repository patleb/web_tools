class Exception
  def self.wtf
    yield
  rescue => e
    puts e.backtrace_log
  end

  def self.wtf!
    yield
  rescue => e
    puts e.backtrace_log
    raise
  end

  def backtrace_log(n = ExtRuby.config.backtrace_log_lines)
    log = ["[#{self.class}]"]
    log << message if message != self.class.to_s
    log.concat((backtrace || []).first(n)).join("\n")
  end
end

def wtf(&block)
  Exception.wtf(&block)
end

def wtf!(&block)
  Exception.wtf!(&block)
end
