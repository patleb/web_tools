require './sunzistrano/test/spec_helper'

class Sunzistrano::ContextTest < Minitest::TestCase
  let(:root){ Sunzistrano.root.join('test/fixtures/files') }

  after do
    Setting.rollback!
  end

  test '.new' do
    Setting.reload(env: 'test', app: 'app', root: root)
    sun = Sunzistrano::Context.new('role', option: 'name')
    assert_equal DUMMY_GEMS.to_a, sun.gems.keys.sort.except('sunzistrano')
    assert_equal 'test', sun.env
    assert_equal 'app', sun.app
    assert_equal 'role', sun.role
    assert_equal 'name', sun.option
    assert_equal 'settings_test_app', sun.settings_scope
    %w(settings settings_2nd_gem settings_3rd_gem).each do |root_name|
      %w(shared test app test_app).each do |scope_name|
        assert sun["#{root_name}_#{scope_name}"]
      end
    end
    assert_equal 'sunzistrano_role_test_app', sun.sunzistrano_scope
    %w(sunzistrano sunzistrano_1st_gem sunzistrano_3rd_gem).each do |root_name|
      %w(shared role test role_test app test_app role_app role_test_app).each do |scope_name|
        assert sun["#{root_name}_#{scope_name}"]
      end
    end
    assert_equal 'replaced', sun.replaceable
  end

  context 'out-of-sync lock version' do
    test '.new' do
      assert_raises(Exception) do
        Setting.reload(env: 'test', root: root.join('version_out_of_sync'))
        Sunzistrano::Context.new
      end
    end
  end

  test '#helpers' do
    Setting.reload(env: 'test')
    sun = Sunzistrano::Context.new('provision')
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

  test '#role_recipes' do
    Setting.reload(env: 'test', root: root)
    sun = Sunzistrano::Context.new('provision')
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
