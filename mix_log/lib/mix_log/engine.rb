require 'ext_ruby'
require 'mix_log/configuration'

module MixLog
  class Engine < ::Rails::Engine
    config.before_initialize do
      autoload_models_if_admin('LogLines::Email')
    end

    initializer 'mix_log.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_log.db_partitions' do
      ExtRails.config.db_partitions[:lib_log_lines] = :week
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'mix_log/action_mailer/base/with_email_record'
    end
  end
end
