require './sunzistrano/test/spec_helper'

class Sunzistrano::BashTest < Minitest::Spec
  let(:run_timeout){ false }

  it 'should execute bash tests successfully' do
    assert_equal true, system("bin/bats #{Sunzistrano.root.join('test/bash/**/*')}")
  end
end
