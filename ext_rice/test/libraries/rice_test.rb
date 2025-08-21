require './test/test_helper'
require "mkmf-rice"

module ExtRice
  class RiceTest < Rice::TestCase
    around do |test|
      split_src = ENV['SPLIT_SRC']
      split_mod = ENV['SPLIT_MOD']
      ENV['SPLIT_SRC'] = 'false'
      ENV['SPLIT_MOD'] = 'false'
      test.call
    ensure
      ENV['SPLIT_SRC'] = split_src
      ENV['SPLIT_MOD'] = split_mod
    end

    it 'should build ext.cpp correctly based on rice.yml' do
      ExtRice.with do |config|
        config.root = Pathname.new('ext_rice').expand_path
        config.yml_path = file_fixture_path.join('rice.yml')
        config.dst_path = config.dst_path.dirname.join('yml')
        Rice.create_makefile(dry_run: true, no_gems: true)

        assert_equal file_fixture_path.join('ext.cpp').read, config.dst_path.join('00_ext.cpp').read
      end
    end

    private

    def file_fixture_path
      Pathname.new('ext_rice').join('test/fixtures/files').expand_path
    end
  end
end
