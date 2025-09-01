require './test/test_helper'

class Rails::ApplicationTest < ActiveSupport::TestCase
  test '.app, .stage' do
    assert_equal 'web_tools', Rails.app
    assert Rails.app.is_a?(ActiveSupport::StringInquirer)
    assert Rails.app.default?
    assert_equal 'test_web_tools', Rails.stage
  end

  test '.viable_names' do
    models = Rails.viable_names('models')
    full_size = models.size
    assert 10 < full_size
    models = Rails.viable_names('models', ['Test::RelatedRecord'], ['/test/record.rb'])
    assert models.exclude? 'Test::RelatedRecord'
    assert models.exclude? 'Test::Record'
    assert_equal full_size - 2, models.size
  end
end
