class UserMailerPreview < ActionMailer::Preview
  def verify_email
    mail_link(__method__)
  end

  def reset_password
    mail_link(__method__)
  end

  def restore_user
    mail_link(__method__)
  end

  private

  def mail_link(action)
    UserMailer.with(user: User.unscoped.first).public_send(action)
  end
end
