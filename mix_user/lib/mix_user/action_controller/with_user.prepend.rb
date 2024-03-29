module ActionController::WithUser
  def set_current
    Current.user ||= warden.user(:user) unless local?
    Current.user ||= User::Null.new
    set_current_value(:role, [false].concat(User.roles.keys))
    super
  end

  def default_role
    false
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

    def can?(*args)
      !!admin_path_for(*args)
    end
  end
end
