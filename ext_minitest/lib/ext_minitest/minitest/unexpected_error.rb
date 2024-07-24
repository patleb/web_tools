Minitest::UnexpectedError.class_eval do
  alias_method :old_backtrace, :backtrace
  def backtrace
    return [] if @backtrace_called
    @backtrace_called = true
    old_backtrace
  end
end
