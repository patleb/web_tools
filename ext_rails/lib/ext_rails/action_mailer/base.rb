require 'ext_rails/email_prefixer/interceptor' unless Rails.env.local?
require 'ext_rails/mail_interceptor/interceptor/with_mail_to' unless Rails.env.production?

ActionMailer::Base.class_eval do
  include ActiveSupport::LazyLoadHooks::Autorun
end
