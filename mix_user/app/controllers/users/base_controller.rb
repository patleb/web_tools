module Users
  class BaseController < LibController
    before_action :browser_bot! unless Rails.env.local?

    no_authentication only: [:new, :create]

    layout 'users'

    private

    def browser_bot!
      head :forbidden if browser_bot?
    end

    def send_email(name, user_scope = nil)
      user = @user || user_scope.find_by!(email: create_params[:email])
      UserMailer.with(user: user).public_send(name).deliver_later
    rescue ActiveRecord::RecordNotFound
      # do nothing
    end
  end
end
