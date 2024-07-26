require './test/spec_helper'

class SymbolTest < Minitest::TestCase
  test '#with' do
    assert [2, 4, 6], [1, 2, 3].map(&:*.with(2))
  end
end
