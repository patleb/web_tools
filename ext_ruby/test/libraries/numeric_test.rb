require './test/spec_helper'
require 'ext_ruby'

class NumericTest < Minitest::Spec
  it 'should simplify numbers with at least 5x 9s or 0s after the leading numbers' do
    assert_equal 0.19999, 0.19999.simplify
    assert_equal 0.2, 0.199999.simplify
    assert_equal 0.100009, 0.100009.simplify
    assert_equal 0.1, 0.1000009.simplify
    assert_equal 199_990, 199_990.simplify
    assert_equal 2_000_000, 1_999_990.simplify
    assert_equal 1_000_099, 1_000_099.simplify
    assert_equal 1_000_000, 1_000_009.simplify
    assert_equal 0.0, 0.0.simplify
    assert_equal 9_999, 9_999.simplify
    assert_equal 100_000, 99_999.simplify
  end
end
