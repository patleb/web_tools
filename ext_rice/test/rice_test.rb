require './test/test_helper'

module ExtRice
  class RiceTest < Rice::TestCase
    test_yml 'ext_rice', yml_path: file_fixture_path('ext_rice').join('rice.yml')
    test_cpp 'ext_rice'

    test 'NArray#to_sql' do
      [:_to_sql_, :to_sql].each do |to_sql|
        assert_equal '{}', Numo::Int8.new(0).seq.send(to_sql)
        assert_equal '{{}}', Numo::Int8.new(0, 0).seq.send(to_sql)
        assert_equal (d1 = '{0,1}'), Numo::Int8.new(2).seq.send(to_sql)
        assert_equal (d2 = "{#{d1},{2,3}}"), Numo::Int8.new(2, 2).seq.send(to_sql)
        assert_equal (d3 = "{#{d2},{{4,5},{6,7}}}"), Numo::Int8.new(2, 2, 2).seq.send(to_sql)
        assert_equal (d4 = "{#{d3},{{{8,9},{10,11}},{{12,13},{14,15}}}}"), Numo::Int8.new(2, 2, 2, 2).seq.send(to_sql)
        assert_equal "{#{d4},{{{{16,17},{18,19}},{{20,21},{22,23}}},{{{24,25},{26,27}},{{28,29},{30,31}}}}}", Numo::Int8.new(2, 2, 2, 2, 2).seq.send(to_sql)
      end
      array = Numo::DFloat.new(2, 2).seq
      array[0, 0] = Float::NAN
      array[0, 1] = Float::INFINITY
      array[1, 0] = -Float::INFINITY
      assert_equal '{{NaN,Infinity},{-Infinity,3.0}}', array._to_sql_
      assert_equal '{{nan,inf},{-inf,3}}', array.to_sql
    end
  end
end
