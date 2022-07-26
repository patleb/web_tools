require './test/spec_helper'
require 'ext_ruby'

class ArrayTest < Minitest::Spec
  it 'should insert before elements' do
    array = [1]
    assert_equal [2, 1], array.insert_before(1, 2)
    assert_equal [3, 2, 1], array.insert_before(2, 3)
    assert_equal [3, 2, 4, 1], array.insert_before(1, 4)
    assert_equal [3, 2, 4, 1, 5], array.insert_before(0, 5)
  end

  it 'should insert after elements' do
    array = [1]
    assert_equal [1, 2], array.insert_after(1, 2)
    assert_equal [1, 2, 3], array.insert_after(2, 3)
    assert_equal [1, 4, 2, 3], array.insert_after(1, 4)
    assert_equal [1, 4, 2, 3, 5], array.insert_after(-1, 5)
  end

  it 'should switch elements' do
    array = [1, 2, 3]
    assert_equal [2, 2, 3], array.switch!(1, 2)
    assert_equal [3, 2, 3], array.switch!(2, 3)
    assert_equal [3, 4, 3], array.switch!(2, 4)
  end
end
