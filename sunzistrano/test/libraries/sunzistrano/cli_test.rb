require './test/spec_helper'
require 'sunzistrano'

ROOT = Sunzistrano.root.join('test/fixtures/files')

class Sunzistrano::CliTest < Minitest::Spec
  let(:cli){ Sunzistrano::Cli.new }

  it 'should build path relative to the owner provisioned dir' do
    path = Sunzistrano.owner_path :manifest_dir, 'version'
    assert_equal '/home/ubuntu/system-test-web_tools/sun_manifest/version', path
  end
end
