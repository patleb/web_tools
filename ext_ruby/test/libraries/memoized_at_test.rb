require './test/spec_helper'

class SimpleClass
  include MemoizedAt

  def access_time(**options)
    m_access(__method__, **options) do
      Time.current
    end
  end
end

class MemoizedAtTest < Minitest::TestCase
  subject{ SimpleClass.new }

  describe '#m_access' do
    it 'should memoize until timeout reached' do
      previous = subject.access_time
      assert_equal subject.access_time, previous
      travel_to (ExtRuby.config.memoized_at_timeout + 1).seconds.from_now do
        current = subject.access_time
        refute_equal current, previous
        assert_equal subject.access_time, current
      end
    end

    it 'should not memoize when force is used' do
      previous = subject.access_time
      travel_to (ExtRuby.config.memoized_at_timeout - 1).seconds.from_now do
        current = subject.access_time(force: true)
        refute_equal current, previous
      end
      previous = subject.access_time
      travel_to (ExtRuby.config.memoized_at_timeout + 1).seconds.from_now do
        current = subject.access_time
        assert_equal current, previous
      end
    end
  end
end
