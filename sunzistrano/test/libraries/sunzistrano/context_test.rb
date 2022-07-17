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
    sun = Sunzistrano::Context.new('test:app', 'role', option: 'name', root: ROOT)
    assert_equal DUMMY_GEMS.to_a, sun.gems.keys.sort
    assert_equal 'test', sun.env
    assert_equal 'app', sun.app
    assert_equal 'role', sun.role
    assert_equal 'name', sun.option
    assert_equal 'settings_app_test', sun.settings_scope
    %w(settings settings_second_gem settings_third_gem).each do |root_name|
      %w(shared test app app_test).each do |scope_name|
        assert sun["#{root_name}_#{scope_name}"]
      end
    end
    assert_equal 'sunzistrano_app_test_role', sun.sunzistrano_scope
    %w(sunzistrano sunzistrano_first_gem sunzistrano_third_gem).each do |root_name|
      %w(shared role test test_role app app_role app_test app_test_role).each do |scope_name|
        assert sun["#{root_name}_#{scope_name}"]
      end
    end
    assert_equal 'replaced', sun.replaceable
  end

  it 'should raise on out-of-sync lock version' do
    assert_raises(Exception) do
      Sunzistrano::Context.new('test', 'system', root: ROOT.join('version_out_of_sync'))
    end
  end

  describe '#helpers' do
    it 'should list Sunzistrano gem helpers' do
      sun = Sunzistrano::Context.new('test', 'system')
      actual_helpers = Set.new(sun.helpers(Sunzistrano.root))
      expected_helpers = %w(
        sun/command_helper.sh
        sun/recipe_helper.sh
        sun/template_helper.sh
        sun/version_helper.sh
        sun_helper.sh
      )
      expected_helpers.each do |helper|
        assert_includes actual_helpers, helper
      end
    end
  end

  describe '#role_recipes' do
    it 'should resolve :(append|remove)_recipes lists' do
      sun = Sunzistrano::Context.new('test', 'system', root: ROOT)
      expected_recipes = %w(
        'first/recipe-value'
        'second/recipe'
        shared/after/second/recipe
        test/before/shared/append
        shared/append
        test/after/shared/append
        test/append
        reboot
      )
      actual_recipes = []
      sun.role_recipes(*%w(
        reboot
        first/recipe-{variable}
        second/recipe-{no_variable}
      )) do |name, id|
        actual_recipes << (id || name)
      end
      assert_equal expected_recipes, actual_recipes
    end
  end
end
