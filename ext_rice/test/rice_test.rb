require './test/test_helper'

module ExtRice
  class RiceTest < Rice::TestCase
    test_yml 'ext_rice', yml_path: file_fixture_path('ext_rice').join('rice.yml')
    test_cpp 'ext_rice'

    test 'Tensor#to_sql' do
      assert_equal (d1 = '{0,1}'), Tensor::Int8.new(2).seq.to_sql
      assert_equal (d2 = "{#{d1},{2,3}}"), Tensor::Int8.new(2, 2).seq.to_sql
      assert_equal (d3 = "{#{d2},{{4,5},{6,7}}}"), Tensor::Int8.new(2, 2, 2).seq.to_sql
      assert_equal (d4 = "{#{d3},{{{8,9},{10,11}},{{12,13},{14,15}}}}"), Tensor::Int8.new(2, 2, 2, 2).seq.to_sql
      assert_equal "{#{d4},{{{{16,17},{18,19}},{{20,21},{22,23}}},{{{24,25},{26,27}},{{28,29},{30,31}}}}}", Tensor::Int8.new(2, 2, 2, 2, 2).seq.to_sql
      array = Tensor::DFloat.new(2, 2).seq
      array[0, 0] = Float::NAN
      array[0, 1] = Float::INFINITY
      array[1, 0] = -Float::INFINITY
      assert_equal '{{nan,inf},{-inf,3}}', array.to_sql
    end
  end
end
