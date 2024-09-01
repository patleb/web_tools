require './test/spec_helper'
require 'mix_setting'

class SettingTest < Minitest::TestCase
  let(:root){ MixSetting.root.join('test/fixtures/files') }
  let(:env){ 'test' }
  let(:app){ 'main' }
  let(:secret_value){ root.join('escaped_file.txt').read }

  after do
    Setting.rollback!
  end

  context 'without version' do
    before do
      Setting.reload(env: env, app: app, root: root)
    end

    test '.all' do
      assert_settings scope: 'settings_test', shared: true, test: true, app: nil, test_app: nil
      assert_equal 'web_tools', Setting.default_app
      Setting.db do |*db_config|
        assert_equal ['127.0.0.2', 5430, 'main_name', '2nd_name', nil], db_config
      end
      assert_equal secret_value, Setting[:secret_value]
      assert_equal secret_value, Setting.decrypt(Setting.encrypt(secret_value))

      assert_equal :method_value,         Setting[:method_value]
      assert_equal :method_1st_alias,     Setting[:method_1st_value]
      assert_equal Setting[:db_database], Setting[:db_3rd_database]
      assert_equal false,                 Setting.has_key?(:remove_2nd_value)
      assert_equal 'overwrite',           Setting[:replace_2nd_value]

      assert_equal [1, 2.0, 'true', "'false'"], Setting[:csv]
      assert_equal %w(a@b.com c@d.com e@f.com g@h.com i@j.com), Setting[:emails]
      assert_equal ([true] * 4 + [false] * 4), Setting[:booleans]
      assert_equal [1, 2, 3, 4, 5],            Setting[:integers]
      assert_equal ['value'],                  Setting[:array]
      assert_equal({ a: 1, b: 2 },             Setting[:json])
      assert_equal '1e1000'.to_d,              Setting[:decimal]
      assert_equal 2.days + 1.minute,          Setting[:interval]
      assert_equal Pathname.new('tmp/test'),   Setting[:pathname]
    end

    context 'with app' do
      let(:app){ 'app' }

      test '.all' do
        assert_settings scope: 'settings_test_app', shared: true, test: true, app: true, test_app: true
      end
    end
  end

  context 'with version' do
    let(:root){ MixSetting.root.join('test/fixtures/files/version_out_of_sync') }

    test '.validate_version!' do
      assert_raises(Exception) do
        Setting.reload(env: env, app: app, root: root)
      end
    end
  end

  private

  def assert_settings(scope:, shared:, test:, app:, test_app:)
    assert_equal "#{env}_#{self.app}", Setting.stage
    assert_equal env,                  Setting.env
    assert_equal self.app,             Setting.app
    assert_equal root,                 Setting.root
    assert_equal scope,                Setting[:settings_scope]
    %w(settings settings_2nd_gem settings_3rd_gem).each do |root_name|
      assert_equal shared,   Setting["#{root_name}_shared"]
      assert_equal test,     Setting["#{root_name}_test"]
      assert_equal app,      Setting["#{root_name}_app"]
      assert_equal test_app, Setting["#{root_name}_test_app"]
    end
  end
end
