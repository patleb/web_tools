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
end
