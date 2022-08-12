require './sunzistrano/test/spec_helper'

class Sunzistrano::Cli::RakeTest < Minitest::Spec
  it 'should insert task string with escaped single quotes' do
    assert_output(%r{bin/rake first_task second_task\[1, "ab c"\] ENV_VAR=\\'hello world\\'}) do
      Sunzistrano::Cli.start(['rake', 'test', %{first_task second_task[1, "ab c"] ENV_VAR='hello world'}])
    end
    Setting.rollback!
  end
end
