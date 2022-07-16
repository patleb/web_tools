require './test/spec_helper'
require 'sunzistrano'

ROOT = Sunzistrano.root.join('test/fixtures/files')

DUMMY_GEMS = Set.new(%w(
  first_gem
  second_gem
  third_gem
))

module Gem
  def self.root(name)
    if DUMMY_GEMS.include? name
      ROOT.join('gems', name)
    elsif (spec = Gem.loaded_specs[name])
      Pathname.new(spec.gem_dir)
    end
  end
end

class Sunzistrano::ContextTest < Minitest::Spec
  it 'should build context correctly' do
    context = Sunzistrano::Context.new('test:app', 'role', option: 'name', root: ROOT)
    assert_equal DUMMY_GEMS.to_a, context.gems.keys.sort
    assert_equal 'test', context.env
    assert_equal 'app', context.app
    assert_equal 'role', context.role
    assert_equal 'name', context.option
    assert_equal 'settings_app_test', context.settings_scope
    %w(settings settings_second_gem settings_third_gem).each do |root_name|
      %w(shared test app app_test).each do |scope_name|
        assert context["#{root_name}_#{scope_name}"]
      end
    end
    assert_equal 'sunzistrano_app_test_role', context.sunzistrano_scope
    %w(sunzistrano sunzistrano_first_gem sunzistrano_third_gem).each do |root_name|
      %w(shared role test test_role app app_role app_test app_test_role).each do |scope_name|
        assert context["#{root_name}_#{scope_name}"]
      end
    end
    assert_equal 'replaced', context.replaceable
  end

  it 'should raise on out-of-sync lock version' do
    assert_raises(Exception) do
      Sunzistrano::Context.new('test', 'system', root: ROOT.join('version_out_of_sync'))
    end
  end
end
