require 'mix_email/email_prefixer/interceptor' unless Rails.env.dev_or_test?
require 'mix_email/mail_interceptor/interceptor/with_mail_to' unless Rails.env.production?
require 'mix_email/action_mailer/base/with_email_record'

ActionMailer::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
end
