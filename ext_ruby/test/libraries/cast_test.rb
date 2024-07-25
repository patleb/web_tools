require './test/spec_helper'

class CastTest < Minitest::TestCase
  test '#cast_self' do
    assert_equal true, true.cast_self
    assert_equal false, false.cast_self
    assert_equal 2, 2.cast_self
    assert_equal 3.0, 3.0.cast_self
    assert_equal BigDecimal('4.0e1000'), BigDecimal('4.0e1000').cast_self
    assert_equal :symbol, :symbol.cast_self
    assert_equal '2000-01-01T00:00:00Z', Time.utc(2000).cast_self
    assert_equal '/', Pathname.new('/').cast_self
    assert_equal nil, ''.cast_self
    assert_equal 5, '5'.cast_self
    assert_equal 6.0, '6.0'.cast_self
    assert_equal '7.0e1000'.to_d, '7.0e1000'.cast_self
    assert_equal true, 'true'.cast_self
    assert_equal false, 'false'.cast_self
    assert_equal 'invalid', 'invalid'.cast_self
    assert_equal(
      [8, 9.0, '10.0E1000'.to_d, true, false, 'invalid'],
      %w(8 9.0 10.0E1000 true false invalid).cast_self
    )
    assert_equal(
      { a: 1, '2nd Float' => Float, b: ['2000-01-01T00:00:00Z'], 3 => 4 },
      { 'a' => '1', '2nd Float' => Float, b: [Time.utc(2000)], 3 => 4}.cast_self
    )
  end
end
