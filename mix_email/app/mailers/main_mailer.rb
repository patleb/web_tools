class MainMailer < ActionMailer::Base
  default from: Setting[:mail_from]

  def healthcheck
    mail to: Setting[:mail_to], template_path: 'main_mailer' # needed for inheritance --> mailer_name is used otherwise
  end
end
