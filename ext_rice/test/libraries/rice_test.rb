require './test/spec_helper'
require 'ext_rice'

class RiceTest < Minitest::Spec
  it 'should complie ext.cpp correctly based on rice.yml' do
    fixtures_files = Gem.root('ext_rice').join('test/fixtures/files')
    compiled_files = Bundler.root.join('tmp/rice/test')

    Rice.config(fixtures_files.join('rice.yml'))
    Rice.dst(compiled_files)
    Rice.create_makefile(numo: false, dry_run: true)

    assert_equal fixtures_files.join('ext.cpp').read, compiled_files.join('ext.cpp').read
  end
end
