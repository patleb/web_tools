module ActionController::WithUser
  def set_current
    warden.authenticated?(:user) unless try(:batch?) # TODO or add Devise to BatchController?
    Current.user ||= User::Null.new
    Current.user.as_user = params[:_as_user].present?
    super
  end

  def current_user
    Current.user
  end

  if defined? MixAdmin
    def admin_path_for(action, object, **params)
      current_controller = Current.controller
      Current.controller = RailsAdmin::MainController.new unless current_controller.try(:admin?)
      case object
      when Class, String, Symbol
        Current.controller.authorized_path_for(action, object, **params)
      else
        Current.controller.authorized_path_for(action, object.class, object, **params)
      end
    ensure
      Current.controller = current_controller
    end
    alias_method :can?, :admin_path_for
  end
end
