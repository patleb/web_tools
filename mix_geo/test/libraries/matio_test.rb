require './test/test_helper'

class MatIOTest < Rice::TestCase
  test '#new, #vars, #read' do
    assert_equal MatIO::V5, MatIO::V_DEFAULT
    [4, 5].each do |version|
      MatIO::File.open(path(version)) do |f|
        assert_equal MatIO.const_get("V#{version}"), f.version
        vars = f.vars
        case version
        when 4
          assert_equal [2,3], vars[:var_1].shape.to_a
          assert_equal [1,2,3,4,5,6], vars[:var_1].read.to_a
        when 5
          assert_equal [2,3], vars[:var_1].shape.to_a
          assert_equal [1,2,3,4,5,6], vars[:var_1].read.to_a
          assert_equal [1,2,3,4,5,6], vars.dig(:nest_1, 0, :var_1).read.to_a
          assert_equal [1,2,3], (0..2).map{ |i| vars.dig(:cell_1, i).read.to_a.first }
          assert_equal 'string', vars[:var_2].read.first
          assert_equal 'string', vars.dig(:nest_1, 0, :var_2).read.first
        end
      end
    end
  end

  private

  def path(version)
    Gem.root('mix_geo').join("test/fixtures/files/data_v#{version}.mat")
  end
end
