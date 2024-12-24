### References
# https://github.com/grosser/maxitest

Minitest::Test.class_eval do
  DEFAULT_TIMEOUT = 2

  class << self
    alias_method :order_dependent!, :i_suck_and_my_tests_are_order_dependent!
  end

  module self::WithTimeout
    def run(...)
      seconds = defined?(run_timeout) ? run_timeout : DEFAULT_TIMEOUT
      if seconds == false
        super
      else
        Timeout.timeout(seconds){ super }
      end
    rescue Timeout::Error => e
      failures << Minitest::UnexpectedError.new(e)
    ensure
      return Minitest::Result.from(self)
    end
  end

  module self::WithAround
    def run(...)
      if defined? around
        result = nil
        around{ result = super }
        result
      else
        super
      end
    end
  end

  prepend self::WithAround
  prepend self::WithTimeout
end
