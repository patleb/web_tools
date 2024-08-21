class UserMailer < LibMailer
  before_action :set_user

  def verify_email
    mail_link :verified
  end

  def reset_password
    mail_link :password
  end

  def restore_user
    mail_link :deleted
  end

  private

  def set_user
    @user = params[:user]
  end

  def mail_link(edit)
    @token = @user.generate_token_for(edit)
    mail to: @user.email, subject: i18n_subject
  end
end
