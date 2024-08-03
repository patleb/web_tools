# frozen_string_literal: true

class LibMailer < ActionMailer::Base
  default from: Setting[:mail_from]

  def healthcheck
    mail to: Setting[:mail_to], template_path: 'lib_mailer' # needed for inheritance --> mailer_name is used otherwise
  end
end
