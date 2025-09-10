require './sunzistrano/test/spec_helper'

class Sunzistrano::CliTest < Minitest::TestCase
  after do
    Setting.rollback!
  end

  test '.owner_path' do
    Setting.reload(env: 'test')
    path = Sunzistrano.owner_path :manifest_dir, 'version'
    assert_equal '/home/ubuntu/test/sun_manifest/version', path
  end

  test '.compile' do
    Sunzistrano::Cli.start(['compile', 'test_app', '--deploy'])
    revision = `git rev-parse origin/master`.strip
    revision_dir = "#{Sunzistrano::BASH_DIR}/#{revision}"
    stage_path = "#{revision_dir}/test_app"
    %w(
      helpers/sun/role_helper.sh
      helpers/sun/recipe_helper.sh
      helpers/sun_helper.sh
      recipes/deploy/start.sh
      recipes/deploy/started.sh
      roles/deploy.sh
      roles/deploy_before.sh
      roles/deploy_ensure.sh
      roles/deploy/load_defaults.sh
      scripts/helper.sh
      scripts/version.sh
      helpers.sh
      role.sh
      role_after.sh
      role_before.sh
      role.sh
      script_after.sh
      script_before.sh
    ).each do |file|
      assert_path_exists "#{stage_path}/#{file}"
    end
    unless ENV['DEBUG'].to_b
      FileUtils.rm_rf stage_path
      FileUtils.rmdir revision_dir rescue nil
    end
  end
end
