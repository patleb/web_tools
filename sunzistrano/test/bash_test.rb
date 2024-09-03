require './sunzistrano/test/spec_helper'

class Sunzistrano::BashTest < Minitest::TestCase
  let(:run_timeout){ false }

  test 'bash' do
    assert_equal true, system("bin/bats #{Sunzistrano.root.join('test/bash/**/*')}")
  end
end
