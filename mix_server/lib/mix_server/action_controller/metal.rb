require_dir __FILE__, 'metal'

module ActionController::WithMixServer
  extend ActiveSupport::Concern

  class_methods do
    def inherited(subclass)
      super
      if subclass.metal_grandparent?
        subclass.include ActionController::WithLog
      end
      subclass.include ActionController::WithErrors
    end
  end
end
