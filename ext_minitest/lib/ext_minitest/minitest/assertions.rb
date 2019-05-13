module Minitest::Assertions
  def assert_until(*equal, sleep: nil)
    location = caller_location
    expected = equal.first if equal.any?
    throttle = sleep.to_i > 0 ? sleep : nil
    until (result = yield; equal.any? ? (result == expected) : result)
      throttle ? sleep(throttle) : Thread.pass
    end
  ensure
    _assert_result result, location, equal
    @_assert_after&.each do |block, location, equal|
      _assert_result block.call, location, equal
    end
    @_assert_after = nil
  end

  def assert_after(*equal, &block)
    @_assert_after ||= []
    @_assert_after << [block, caller_location, equal]
  end

  private

  def _assert_result(result, location, equal)
    if equal.any?
      result = result.symbolize_keys if result.is_a? Hash
      assert_equal equal.first, result, "\n#{location}"
    else
      assert result, "Expected { #{mu_pp result} } to be truthy.\n#{location}"
    end
  end
end
