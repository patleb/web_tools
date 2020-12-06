require 'mix_email/mail_interceptor/interceptor/with_mail_to' unless Rails.env.production?
require 'mix_email/action_mailer/base/with_attachment_fix'
require 'mix_email/action_mailer/base/with_email_record'

ActionMailer::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
end
