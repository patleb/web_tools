module LibController::WithUserSession
  private

  def create_session!(user)
    user.create_session! ip_address: request.remote_ip, user_agent: user_agent
    Current.user = user
    Current.role = user.role
    session[:user_id] = user.id
    session.delete(:role)
    cookies.delete(:_role)
  end

  def destroy_session!(user)
    user.session&.destroy!
    Current.user = User::Null.new
    Current.role = :null
    reset_session
    cookies.clear
  end
end
