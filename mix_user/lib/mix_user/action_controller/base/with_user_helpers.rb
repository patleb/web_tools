module ActionController::Base::WithUserHelpers
  extend ActiveSupport::Concern

  included do
    helper MixUser::Engine.helpers
    helper_method :current_user
    helper_method :admin_path_for, :can? if defined? MixAdmin
  end
end

ActionController::Base.include ActionController::Base::WithUserHelpers
