require './ext_rice/test/spec_helper'

class ExtRice::CppTest < Minitest::Spec
  let(:run_timeout){ false }

  it 'should execute c++ tests successfully' do
    assert_equal true, system("bin/rake rice:test_compile[ext_rice,test/ext_rice]")
    assert_equal true, system("tmp/rice/test/ext_rice/unittest")
  end
end
