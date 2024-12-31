module Users
  class BaseController < LibController
    no_authentication only: [:new, :create]

    layout 'users'

    private

    def send_email(name, user_scope = nil)
      user = @user || user_scope.find_by!(email: create_params[:email])
      UserMailer.with(user: user).public_send(name).deliver_later
    rescue ActiveRecord::RecordNotFound
      # do nothing
    end
  end
end
