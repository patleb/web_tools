class MainMailer < ActionMailer::Base
  default from: Setting[:mail_from]

  def healthcheck
    mail to: Setting[:mail_to], template_path: 'main_mailer'
  end
end
