require './test/test_helper'

class ThrottlerTest < ActiveSupport::TestCase
  let(:throttle_key){ 'key' }
  let(:throttle_value){ 'value' }
  let(:throttle_to){ 1 }

  context 'no max duration' do
    before do
      MixServer::Rescue.config.throttler_max_duration = 0.second
      assert_equal({ limit: false }, throttle)
    end

    test '.increment' do
      assert_equal({ limit: false, was: [throttle_value, 1] }, throttle)
      assert_equal({ limit: false, was: [throttle_value, 1] }, throttle)
      assert_equal({ limit: false, was: [throttle_value, 1] }, throttle(value: 'different'))
      assert_equal({ limit: false, was: ['different', 1] }, throttle(value: 'different'))
    end
  end

  context 'with 10 seconds max duration' do
    before do
      MixServer::Rescue.config.throttler_max_duration = 10.seconds
      assert_equal({ limit: false }, throttle)
    end

    test '.increment' do
      assert_equal({ limit: true, was: [throttle_value, 1] }, throttle)
      assert_equal({ limit: true, was: [throttle_value, 2] }, throttle)
      travel_to 10.seconds.from_now do
        assert_equal({ limit: false, was: [throttle_value, 3] }, throttle)
        assert_equal({ limit: true, was: [throttle_value, 1] }, throttle)
      end
    end

    context 'with max count of 2' do
      let(:throttle_to){ 2 }

      test '.increment' do
        assert_equal({ limit: false, was: [throttle_value, 1] }, throttle)
        assert_equal({ limit: true, was: [throttle_value, 2] }, throttle)
        travel_to 10.seconds.from_now do
          assert_equal({ limit: false, was: [throttle_value, 3] }, throttle)
          assert_equal({ limit: false, was: [throttle_value, 1] }, throttle)
          assert_equal({ limit: true, was: [throttle_value, 2] }, throttle)
        end
      end
    end
  end

  def throttle(value: nil, &block)
    Throttler.increment(key: throttle_key, value: value || throttle_value, to: throttle_to, &block)
  end
end
