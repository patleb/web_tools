module ActionController::Base::WithRescue
  extend ActiveSupport::Concern

  class_methods do
    def inherited(subclass)
      super
      if subclass.superclass == ActionController::Base
        subclass.include ActionController::WithStatus
      end
      subclass.include ActionController::WithErrors
    end
  end
end

ActionController::Base.include ActionController::Base::WithRescue
