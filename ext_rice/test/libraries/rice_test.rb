require './ext_rice/test/spec_helper'

class RiceTest < Minitest::Spec
  it 'should complie ext.cpp correctly based on rice.yml' do
    fixtures_files = Gem.root('ext_rice').join('test/fixtures/files')
    compiled_files = Bundler.root.join('tmp/rice/test/ext_rice/test')

    ExtRice.with do |config|
      config.yml_path = fixtures_files.join('rice.yml')
      config.dst_path = compiled_files
      Rice.create_makefile(numo: false, dry_run: true)
    end

    assert_equal fixtures_files.join('ext.cpp').read, compiled_files.join('ext.cpp').read
  end
end
