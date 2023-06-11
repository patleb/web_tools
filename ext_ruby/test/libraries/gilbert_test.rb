require './test/spec_helper'
require 'ext_ruby'

class GilbertTest < Minitest::Spec
  it 'should support 2D grids' do
    curve = [[0, 0], [0, 1], [1, 1], [1, 0], [2, 0], [2, 1], [2, 2], [2, 3], [1, 3], [1, 2], [0, 2], [0, 3]]
    grid  = [[0, 1, 10, 11], [3, 2, 9, 8], [4, 5, 6, 7]]
    indices = (0...3).map{ |i| (0...4).map{ |j| [i, j] } }
    assert_equal curve, Gilbert.curve(3, 4, cache: false)
    assert_equal grid,  Gilbert.grid(3, 4, cache: false)
    assert_equal indices, grid.map{ |row| row.map{ |col| curve[col] } }
  end

  it 'should support 3D grids' do
    curve = [
      [0, 0, 0], [0, 0, 1], [1, 0, 1], [1, 0, 0], [1, 1, 0], [1, 1, 1], [0, 1, 1], [0, 1, 0], [0, 2, 0],
      [1, 2, 0], [1, 2, 1], [0, 2, 1], [0, 2, 2], [1, 2, 2], [1, 2, 3], [0, 2, 3], [0, 1, 3], [0, 1, 2],
      [1, 1, 2], [1, 1, 3], [1, 0, 3], [1, 0, 2], [0, 0, 2], [0, 0, 3]
    ]
    grid = [
      [[0, 1, 22, 23], [7, 6, 17, 16], [8, 11, 12, 15]],
      [[3, 2, 21, 20], [4, 5, 18, 19], [9, 10, 13, 14]],
    ]
    indices = (0...2).map{ |i| (0...3).map{ |j| (0...4).map{ |k| [i, j, k] } } }
    assert_equal curve, Gilbert.curve(2, 3, 4, cache: false)
    assert_equal grid,  Gilbert.grid(2, 3, 4, cache: false)
    assert_equal indices, grid.map{ |x| x.map{ |y| y.map{ |z| curve[z] } } }
  end
end
