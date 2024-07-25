require './test/spec_helper'

class BulkProcessorTest < Minitest::TestCase
  test '#process, #finalize' do
    total, args = 0, []
    list = BulkProcessor.new(5) do |batch, *plus|
      total += batch.size
      args.concat(plus)
    end
    list << 1
    list.process(1)
    assert_equal 0, total
    assert_equal [], args
    list.concat [2, 3]
    list.process(2, 3)
    assert_equal 0, total
    assert_equal [], args
    list.concat [4, 5]
    list.process(4, 5)
    assert_equal 5, total
    assert_equal [4, 5], args
    list << 6
    list.process(6)
    assert_equal 5, total
    assert_equal [4, 5], args
    list.finalize(7)
    assert_equal 6, total
    assert_equal [4, 5, 7], args
  end
end
