require 'ext_rails'
require 'mix_email/configuration'

module MixEmail
  class Engine < ::Rails::Engine
    require 'email_prefixer'
    require 'mix_email/action_mailer/smtp_settings'
    require 'mix_log'

    config.before_configuration do |app|
      app.config.action_mailer.delivery_method = :smtp
      app.config.action_mailer.smtp_settings = ActionMailer::SmtpSettings.new(Setting)
      app.config.action_mailer.default_url_options = Setting[:default_url_options]
    end

    config.before_initialize do
      autoload_models_if_admin('LogLines::Email')

      if Rails.env.dev_or_test?
        Rails::Initializable::Initializer.exclude_initializers['EmailPrefixer::Railtie'] = 'email_prefixer.configure_defaults'
      end
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
