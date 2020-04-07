module ActionController::WithUser
  def set_current
    warden.authenticated?(:user) unless try(:batch?) # TODO or add Devise to BatchController?
    Current.user ||= User::Null.new
    super
  end

  def current_user
    Current.user
  end
end
