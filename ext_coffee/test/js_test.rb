require './ext_coffee/test/spec_helper'

class JsTest < Minitest::Spec
  let(:run_timeout){ false }

  after do
    `bin/yarn test-clear`
  end

  it 'should execute js tests successfully' do
    assert_equal false, system("bin/yarn test 2>&1 | grep 'FAIL'")
  end
end
