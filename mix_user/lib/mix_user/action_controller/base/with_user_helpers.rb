module ActionController::Base::WithUserHelpers
  extend ActiveSupport::Concern

  included do
    helper MixUser::Engine.helpers
    helper_method :current_user
  end
end

ActionController::Base.include ActionController::Base::WithUserHelpers
