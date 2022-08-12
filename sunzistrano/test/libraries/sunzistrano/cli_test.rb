require './sunzistrano/test/spec_helper'

class Sunzistrano::CliTest < Minitest::Spec
  it 'should build path relative to the owner provisioned dir' do
    Setting.reload(env: 'test')
    path = Sunzistrano.owner_path :manifest_dir, 'version'
    assert_equal '/home/ubuntu/test-web_tools/sun_manifest/version', path
  end

  it 'should compile' do
    Sunzistrano::Cli.start(['compile', 'test-app', '--deploy'])
    revision = `git rev-parse origin/master`.strip
    FileUtils.rm_rf "#{Sunzistrano::BASH_DIR}/#{revision}/test-app"
    FileUtils.rmdir "#{Sunzistrano::BASH_DIR}/#{revision}" rescue nil
    Setting.rollback!
  end
end
