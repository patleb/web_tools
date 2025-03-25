require './test/spec_helper'

class ArrayTest < Minitest::TestCase
  test '#to_sql' do
    assert_equal '{}', [].to_sql
    assert_equal '{}', [].to_sql(0)
    assert_equal '{{}}', [].to_sql(0, 0)
    assert_equal (d1 = '{0,1}'), (0..1).to_a.to_sql(2)
    assert_equal (d2 = "{#{d1},{2,3}}"), (0..3).to_a.to_sql(2, 2)
    assert_equal (d3 = "{#{d2},{{4,5},{6,7}}}"), (0..7).to_a.to_sql(*[2] * 3)
    assert_equal (d4 = "{#{d3},{{{8,9},{10,11}},{{12,13},{14,15}}}}"), (0..15).to_a.to_sql(*[2] * 4)
    assert_equal "{#{d4},{{{{16,17},{18,19}},{{20,21},{22,23}}},{{{24,25},{26,27}},{{28,29},{30,31}}}}}", (0..31).to_a.to_sql(*[2] * 5)
  end

  test '#mode' do
    assert_equal 2.0, [1.0, 2.0, 2.0, 3.0, 4.0].mode
  end

  test '#average' do
    assert_nil [].average
    assert_equal 2.0, [1, 2, 3].average
    assert_equal 4.0, [1, 2, 3].average{ |i| i * 2 }
  end

  test '#variance' do
    assert_nil [].variance
    assert_equal 0.5, [1, 2, 2, 3].variance
    assert_equal 0.5, [1, 2, 2, 3].variance(2)
  end

  test '#percentile, #median' do
    assert_nil [].median
    array = [30, 33, 43, 53, 56, 67, 68, 72]
    assert_equal 30, array.percentile(0.0)
    assert_equal 40.5, array.percentile(0.25)
    assert_equal 54.5, array.median
    assert_equal 67.25, array.percentile(0.75)
    assert_equal 72, array.percentile(1.0)
  end

  test '#join!' do
    assert_equal '1abc23e', [1, 'abc', nil, '', 2, nil, 3, 'e', ''].join!
  end

  test '#except' do
    assert_equal [1, 5], [1, 2, 3, 4, 5].except(2, 3, 4)
  end

  test '#insert_before' do
    array = [1]
    assert_equal [2, 1], array.insert_before(1, 2)
    assert_equal [3, 2, 1], array.insert_before(2, 3)
    assert_equal [3, 2, 4, 1], array.insert_before(1, 4)
    assert_equal [3, 2, 4, 1, 5], array.insert_before(0, 5)
  end

  test '#insert_after' do
    array = [1]
    assert_equal [1, 2], array.insert_after(1, 2)
    assert_equal [1, 2, 3], array.insert_after(2, 3)
    assert_equal [1, 4, 2, 3], array.insert_after(1, 4)
    assert_equal [1, 4, 2, 3, 5], array.insert_after(-1, 5)
  end

  test '#switch' do
    array = [1, 2, 3]
    assert_equal [2, 2, 3], array.switch!(1, 2)
    assert_equal [3, 2, 3], array.switch!(2, 3)
    assert_equal [3, 4, 3], array.switch!(2, 4)
  end

  test '#intersperse' do
    assert_equal [1, 4, 2, 4, 3, 4, 1], [1, 2, 3, 1].intersperse(4)
  end

  test '#neg' do
    assert_equal [-2, -3, -4], [2, 3, 4].neg
  end

  test '#mul' do
    assert_equal [4, 6, 8], [2, 3, 4].mul(2)
  end

  test '#div' do
    assert_equal [1, 1.5, 2], [2, 3, 4].div(2.0)
  end

  test '#sub' do
    assert_equal [0, 2], [4, 4].sub([2, 1], [2, 1])
    assert_equal [1, 2, 3], [2, 3, 4].sub([1, 1, 1])
    assert_raises 'size mismatch' do
      [1].sub([1, 2])
    end
  end

  test '#add' do
    assert_equal [8, 6], [4, 4].add([2, 1], [2, 1])
    assert_equal [3, 4, 5], [2, 3, 4].add([1, 1, 1])
    assert_raises 'size mismatch' do
      [1].add([1, 2])
    end
  end

  test '#l0' do
    assert_equal 0.0, [].l0
    assert_equal 3, [1, -2, 3].l0
    assert_equal 2, [2, 4, 6].l0([-2, 6, 6])
    assert_raises 'size mismatch' do
      [1].l0([1, 2])
    end
  end

  test '#l1' do
    assert_equal 0.0, [].l1
    assert_equal 6, [1, -2, 3].l1
    assert_equal 6, [2, 4, 6].l1([-2, 6, 6])
    assert_raises 'size mismatch' do
      [1].l1([1, 2])
    end
  end

  test '#l2_squared' do
    assert_equal 0.0, [].l2_squared
    assert_equal 14, [1, -2, 3].l2_squared
    assert_equal 20, [2, 4, 6].l2_squared([-2, 6, 6])
    assert_raises 'size mismatch' do
      [1].l2_squared([1, 2])
    end
  end

  test '#l_inf' do
    assert_equal 0.0, [].l_inf([])
    assert_equal 3, [1, -2, 3].l_inf([0, 1, 0])
    assert_equal 4, [2, 4, 6].l_inf([-2, 6, 6])
    assert_raises 'size mismatch' do
      [1].l_inf([1, 2])
    end
  end
end
