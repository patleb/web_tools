require 'mix_core/action_mailer/base/with_attachment_fix'
require 'mix_core/action_mailer/base/with_mail_interceptor' if defined? MailInterceptor

ActionMailer::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
end
