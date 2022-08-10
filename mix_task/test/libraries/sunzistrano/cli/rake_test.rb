require './test/spec_helper'
require 'sunzistrano'

class Sunzistrano::Cli::RakeTest < Minitest::Spec
  it 'should insert task string with escaped single quotes' do
    assert_output(%r{bin/rake some_task\[1, "abc"\] ENV_VAR=\\x27hello world\\x27}) do
      Sunzistrano::Cli.start(['rake', 'test', %{some_task[1, "abc"] ENV_VAR='hello world'}])
    end
    Setting.rollback!
  end
end
