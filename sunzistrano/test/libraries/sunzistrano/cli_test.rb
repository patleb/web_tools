require './test/spec_helper'
require 'sunzistrano'

class Sunzistrano::CliTest < Minitest::Spec
  it 'should build path relative to the owner provisioned dir' do
    Setting.reload(env: 'test')
    path = Sunzistrano.owner_path :manifest_dir, 'version'
    assert_equal '/home/ubuntu/test-web_tools/sun_manifest/version', path
  end

  it 'should compile' do
    Sunzistrano::Cli.start(['compile', 'test-app', '--deploy'])
    FileUtils.rm_rf "#{Sunzistrano::BASH_DIR}/test-app"
    Setting.rollback!
  end
end
