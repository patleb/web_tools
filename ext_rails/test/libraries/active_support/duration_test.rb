require './test/test_helper'

class DurationTest < ActiveSupport::TestCase
  let(:interval){ 1.year + 2.months + 3.days + 4.hours + 5.minutes + 6.seconds }

  test '#to_s' do
    assert_equal '37090350 secondes', interval.to_s(:seconds)
    assert_equal '429 jours, 4 heures, 5 minutes, 6 secondes', interval.to_s(:days)
    assert_equal '1a, 2mo, 3j, 4h, 5m, 6s', interval.to_s(:years, compact: true)
  end
end
