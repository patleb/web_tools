require './test/test_helper'

class ActionController::WithMemoizationTest < ActionDispatch::IntegrationTest
  test '#memoize' do
    values = { a: 1 }
    controller_define :expensive do
      memoize(self, :expensive, values) do
        values[:a] += 1
      end
    end
    controller_assert :memoize do
      (expensive + expensive) == 4
    end
    assert_equal 2, values[:a]
  end
end
