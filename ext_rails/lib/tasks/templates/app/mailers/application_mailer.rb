class ApplicationMailer < ActionMailer::Base
  default from: Setting[:mail_from]
  layout 'mailer'
end
