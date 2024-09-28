Admin::Model.class_eval do
  class << self
    alias_method :old_allowed?, :allowed?
    def allowed?(...)
      $test.model_denied ? false : old_allowed?(...)
    end
  end

  alias_method :old_allowed?, :allowed?
  def allowed?(...)
    $test.presenter_denied ? false : old_allowed?(...)
  end
end

module AdminControllerContext
  extend ActiveSupport::Concern

  included do
    fixtures :users
    fixtures 'test/records'

    let(:current_user){ users(:admin) }
    let(:model_name){ Test::Extensions::RecordExtension.name.to_admin_param }
    let(:model_denied){ false }
    let(:presenter_denied){ false }

    around do |test|
      MixAdmin.with do |config|
        config.root = '/model'
        config.record_label_methods = []
        test.call
      end
    end
  end

  private

  def assert_selects(*selectors)
    selectors.each do |selector|
      assert_select(selector)
    end
  end
end
