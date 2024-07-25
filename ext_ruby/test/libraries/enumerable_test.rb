require './test/spec_helper'

class EnumerableTest < Minitest::TestCase
  test '#stable_sort_by' do
    array = [2, 1, 3, 5, 2, 2, 5, 3].map.with_index.to_a
    assert_equal [[1, 1], [2, 0], [2, 4], [2, 5], [3, 2], [3, 7], [5, 3], [5, 6]], array.stable_sort_by(&:first)
  end

  test '#count_by, #tally_by' do
    array = [1, 1, 1, 1, 2, 2, 2, 3, 3, 4].map.with_index.to_a
    assert_equal({ 1 => 4, 2 => 3, 3 => 2, 4 => 1 }, array.count_by(:desc, &:first))
    assert_equal({ 4 => 1, 3 => 2, 2 => 3, 1 => 4 }, array.count_by(:asc, &:first))
    assert_equal({ 1 => 4, 2 => 3, 3 => 2, 4 => 1 }, array.tally_by(&:first))
  end
end
