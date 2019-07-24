module ActionController::API::WithRescue
  extend ActiveSupport::Concern

  class_methods do
    def inherited(subclass)
      super
      if subclass.superclass == ActionController::API
        subclass.include ActionController::WithStatus
      end
      subclass.include ActionController::WithErrors
    end
  end
end
