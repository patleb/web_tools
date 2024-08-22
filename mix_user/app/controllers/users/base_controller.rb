# frozen_string_literal: true

module Users
  class BaseController < LibController
    no_authentication only: [:new, :create]

    layout 'users'

    private

    def create_session!(user)
      user.create_session! ip_address: request.remote_ip, user_agent: user_agent
      Current.user = user
      Current.role = user.role
      clear_role
      session[:user_id] = user.id
    end

    def destroy_session!(user)
      user.session&.destroy!
      Current.user = User::Null.new
      Current.role = :null
      clear_role
      session.delete(:user_id)
    end

    def send_email(name, user_scope = nil)
      user = @user || user_scope.find_by!(email: create_params[:email])
      UserMailer.with(user: user).public_send(name).deliver_later
    rescue ActiveRecord::RecordNotFound
      # do nothing
    end

    def clear_role
      session.delete(:role)
      cookies.delete(:_role)
    end
  end
end
