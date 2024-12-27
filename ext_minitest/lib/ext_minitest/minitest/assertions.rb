module Minitest::Assertions
  def assert_retry(expected, actual = nil, retries: 2)
    result = actual.nil? ? yield : actual
    while result != expected && (retries -= 1) > 0
      result = yield
    end
    assert_equal expected, result
  end

  alias_method :assert_equal_without_nil, :assert_equal
  def assert_equal(exp, act, msg = nil)
    if exp.nil?
      assert_nil(act, msg)
    else
      assert_equal_without_nil(exp, act, msg)
    end
  end

  def assert_until(*equal, sleep: nil)
    location = caller_location
    expected = equal.first if equal.any?
    throttle = sleep.to_f > 0 ? sleep : nil
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
