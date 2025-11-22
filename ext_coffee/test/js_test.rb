require './ext_coffee/test/spec_helper'

class JsTest < Minitest::TestCase
  let(:run_timeout){ false }

  after do
    `yarn test-clear`
  end

  it 'should execute js tests successfully' do
    assert_equal false, system("yarn test 2>&1 | grep -E 'FAIL|Error'")
  end
end
