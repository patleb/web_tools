require './test/rails_helper'

class SimpleClass
  include MemoizedAt

  def access_time(**options)
    m_access(:access_time, **options) do
      Time.now
    end
  end
end

class MemoizedAtTest < ActiveSupport::TestCase
  subject{ SimpleClass.new }

  describe '#m_access' do
    it 'should memoize until threshold passed' do
      previous = subject.access_time
      assert_equal subject.access_time, previous
      travel_to (MemoizedAt::ACCESS_THRESHOLD + 1).seconds.from_now do
        current = subject.access_time
        refute_equal current, previous
        assert_equal subject.access_time, current
      end
    end

    it 'should continue to memoized when touch is used' do
      previous = subject.access_time
      travel_to (MemoizedAt::ACCESS_THRESHOLD - 1).seconds.from_now do
        current = subject.access_time(touch: true)
        assert_equal current, previous
      end
      travel_to (MemoizedAt::ACCESS_THRESHOLD + 1).seconds.from_now do
        current = subject.access_time
        assert_equal current, previous
      end
    end
  end
end
