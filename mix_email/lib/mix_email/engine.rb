require 'ext_rails'

module MixEmail
  class Engine < ::Rails::Engine
    require 'mix_email/action_mailer/smtp_settings'
    require 'mix_log'

    config.before_configuration do |app|
      app.config.action_mailer.delivery_method = :smtp
      app.config.action_mailer.smtp_settings = ActionMailer::SmtpSettings.new(Setting).to_h
      app.config.action_mailer.default_url_options = Setting[:default_url_options]
    end

    config.before_initialize do |app|
      autoload_models_if_admin('LogLines::Email')
      app.config.action_mailer.delivery_job = "MainMailerJob"
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types['LogLines::Email'] = 110
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'mix_email/action_mailer/base'
      require 'mix_email/action_mailer/log_subscriber/with_quiet_info'
    end
  end
end
