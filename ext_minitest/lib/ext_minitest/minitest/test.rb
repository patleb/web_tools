Minitest::Test.class_eval do
  DEFAULT_TIMEOUT = 1

  class << self
    alias_method :order_dependent!, :i_suck_and_my_tests_are_order_dependent!
  end

  alias_method :run_without_timeout, :run
  def run(&block)
    seconds = defined?(run_timeout) ? run_timeout : DEFAULT_TIMEOUT
    if seconds == false
      run_without_timeout(&block)
    else
      Timeout.timeout(seconds){ run_without_timeout(&block) }
    end
  rescue Timeout::Error => e
    failures << Minitest::UnexpectedError.new(e)
  ensure
    return Minitest::Result.from(self)
  end
end
