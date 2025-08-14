require './test/test_helper'

class TensorTest < Rice::TestCase
  test '#operator==' do
    assert Tensor::UInt8.new(2).seq == Tensor::UInt8[0, 0].seq
    refute Tensor::UInt8.new(2).seq == Tensor::UInt8.new(2)
  end

  test '#operator[]' do
    tensor = Tensor::SFloat.new(2, 2).seq
    assert_equal 0.0, tensor[0]
    assert_equal 1.0, tensor[1]
    assert_equal 2.0, tensor[2]
    assert_equal 3.0, tensor[3]
  end

  test '#to_sql' do
    assert_equal (d1 = '{0,1}'), Tensor::UInt8.new(2).seq.to_sql
    assert_equal (d2 = "{#{d1},{2,3}}"), Tensor::UInt8.new(2, 2).seq.to_sql
    assert_equal (d3 = "{#{d2},{{4,5},{6,7}}}"), Tensor::UInt8.new(2, 2, 2).seq.to_sql
    assert_equal (d4 = "{#{d3},{{{8,9},{10,11}},{{12,13},{14,15}}}}"), Tensor::UInt8.new(2, 2, 2, 2).seq.to_sql
    assert_equal "{#{d4},{{{{16,17},{18,19}},{{20,21},{22,23}}},{{{24,25},{26,27}},{{28,29},{30,31}}}}}", Tensor::UInt8.new(2, 2, 2, 2, 2).seq.to_sql
    array = Tensor::DFloat.new(2, 2).seq
    array[0, 0] = Float::NAN
    array[0, 1] = Float::INFINITY
    array[1, 0] = -Float::INFINITY
    assert_equal '{{nan,inf},{-inf,3}}', array.to_sql
    array[0, 0] = array[0, 1] = array[1, 0] = array[1, 1] = Float::NAN
    assert_equal '{{NULL,NULL},{NULL,NULL}}', array.to_sql(nulls: true)
  end

  test '#from_sql' do
    assert_equal Tensor::UInt8.from_sql(d1 = '{0,1}', s = [2]), Tensor::UInt8.new(*s).seq
    assert_equal Tensor::UInt8.from_sql(d2 = "{#{d1},{2,3}}", s << 2), Tensor::UInt8.new(*s).seq
    assert_equal Tensor::UInt8.from_sql(d3 = "{#{d2},{{4,5},{6,7}}}", s << 2), Tensor::UInt8.new(*s).seq
    assert_equal Tensor::UInt8.from_sql(d4 = "{#{d3},{{{8,9},{10,11}},{{12,13},{14,15}}}}", s << 2), Tensor::UInt8.new(*s).seq
    assert_equal Tensor::UInt8.from_sql("{#{d4},{{{{16,17},{18,19}},{{20,21},{22,23}}},{{{24,25},{26,27}},{{28,29},{30,31}}}}}", s << 2), Tensor::UInt8.new(*s).seq
    array = Tensor::DFloat.new(2, 2).seq
    array[0, 0] = Float::NAN
    array[0, 1] = Float::INFINITY
    array[1, 0] = -Float::INFINITY
    assert_equal Tensor::DFloat.from_sql('{{nan,inf},{-inf,3}}', 2, 2).to_sql, array.to_sql
    array[0, 0] = array[0, 1] = array[1, 0] = array[1, 1] = Float::NAN
    assert_equal Tensor::DFloat.from_sql('{{NULL,NULL},{NULL,NULL}}', 2, 2).to_sql, array.to_sql
  end

  test '#reshape' do
    assert_equal [2, 3], Tensor::Int32.new(6).reshape(2, 3).shape
    assert_equal [3, 4], Tensor::Int32.new(1, 3, 4).reshape(false, true, true).shape
  end

  test '#reverse' do
    tensor = Tensor::Int32.new(4, 3).seq
    assert_equal [9, 10, 11, 6, 7, 8, 3, 4, 5, 0, 1, 2], tensor.reverse(0).to_a
    assert_equal [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0], tensor.reverse(1).to_a
    tensor = Tensor::Int32.new(3, 4).seq
    assert_equal [3, 2, 1, 0, 7, 6, 5, 4, 11, 10, 9, 8], tensor.reverse(1).to_a
    assert_equal [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0], tensor.reverse(0).to_a
  end
end
