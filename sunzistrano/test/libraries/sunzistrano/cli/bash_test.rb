require './sunzistrano/test/spec_helper'

class Sunzistrano::Cli::BashTest < Minitest::Spec
  it 'should insert task string with escaped single quotes' do
    env_var = %r{ENV_VAR=\\'hello world\\'}
    version = %r{bash -e -u \+H scripts/version\.sh}
    os_name = %r{helper=sun\.os_name && bash -e -u \+H scripts/helper\.sh 1 "ab c"}
    assert_output(/#{env_var} .+ #{version} .+ #{os_name}/) do
      Sunzistrano::Cli.start(['bash', 'test', %{version sun.os_name[1, "ab c"] ENV_VAR='hello world'}])
    end
    Setting.rollback!
  end
end
