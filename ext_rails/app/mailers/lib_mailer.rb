# frozen_string_literal: true

class LibMailer < ActionMailer::Base
  default from: Setting[:mail_from]

  # NOTE :template_path is needed for inheritance, otherwise 'mailer_name' is used
  def healthcheck
    mail to: Setting[:mail_to], template_path: 'lib_mailer'
  end
end
