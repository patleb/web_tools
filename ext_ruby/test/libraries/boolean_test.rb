require './test/spec_helper'

class BooleanTest < Minitest::TestCase
  test '#to_b, #to_b?' do
    ['true', 't', 'yes', 'y', 'Y', '1', 1, 1.0, true].each do |truthy|
      assert_equal true, truthy.to_b
      assert truthy.to_b?
    end
    ['false', 'f', 'no', 'n', '0', 0, 0.0, false, nil].each do |falsy|
      assert_equal false, falsy.to_b
      assert falsy.to_b?
    end
    ['invalid', -1, 2.0].each do |invalid|
      assert_raises ArgumentError do
        invalid.to_b
      end
      refute invalid.to_b?
    end
    assert false.is_a?(Boolean)
    assert true.is_a?(Boolean)
    refute nil.is_a?(Boolean)
  end
end
