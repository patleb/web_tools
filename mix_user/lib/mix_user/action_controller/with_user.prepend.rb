module ActionController::WithUser
  def set_current
    warden.authenticated?(:user) unless try(:local?)
    Current.user ||= User::Null.new
    Current.user.role_user = params[:_role_user].present?
    super
  end

  def current_user
    Current.user
  end

  if defined? MixAdmin
    def admin_path_for(action, object, **params)
      Current.controller_was = Current.controller
      Current.controller = RailsAdmin::MainController.new unless Current.controller_was.try(:admin?)
      case object
      when Class, String, Symbol
        Current.controller.authorized_path_for(action, object, **params)
      else
        Current.controller.authorized_path_for(action, object.class, object, **params)
      end
    ensure
      Current.controller = Current.controller_was
      Current.controller_was = nil
    end
    alias_method :can?, :admin_path_for
  end
end
