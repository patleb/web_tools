require './test/rails_helper'

class ThrottlerTest < ActiveSupport::TestCase
  let(:throttle_key){ 'key' }
  let(:throttle_value){ 'value' }

  describe '.status' do
    describe 'no max duration' do
      before do
        MixThrottler.config.max_duration = 0.second
        assert_equal({ throttled: false }, throttle)
      end

      describe 'same value' do
        it 'should not be throttled' do
          assert_equal({ throttled: false, previous: throttle_value, count: 1 }, throttle)
          assert_equal({ throttled: false, previous: throttle_value, count: 1 }, throttle)
        end
      end

      describe 'different value' do
        it 'should not be throttled, but send back old value' do
          assert_equal({ throttled: false, previous: throttle_value, count: 1 }, throttle(value: 'different'))
          assert_equal({ throttled: false, previous: 'different', count: 1 }, throttle(value: 'different'))
        end
      end
    end

    describe 'with 10 seconds max duration' do
      before do
        MixThrottler.config.max_duration = 10.seconds
        assert_equal({ throttled: false }, throttle)
      end

      describe 'same value' do
        it 'should be throttled and count increasing' do
          assert_equal({ throttled: true, previous: throttle_value, count: 1 }, throttle)
          assert_equal({ throttled: true, previous: throttle_value, count: 2 }, throttle)
        end

        it 'should reset the throttle after 10 seconds' do
          assert_equal({throttled: true, previous: throttle_value, count: 1 }, throttle)
          travel_to 10.seconds.from_now do
            assert_equal({throttled: false, previous: throttle_value, count: 2 }, throttle)
          end
        end

        describe 'block given' do
          it 'should be throttled if the return value is true' do
            assert_equal({throttled: false, previous: throttle_value, count: 1 }, throttle{ false })
            assert_equal({throttled: true, previous: throttle_value, count: 1 }, throttle{ true })
          end
        end
      end
    end
  end

  def throttle(value: nil, &block)
    Throttler.status(key: throttle_key, value: value || throttle_value, &block)
  end
end
