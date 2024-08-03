require 'ext_ruby'
require 'mix_log/configuration'

module MixLog
  class Engine < ::Rails::Engine
    require 'user_agent_parser'
    require 'mix_log/user_agent_parser/user_agent'

    config.before_initialize do
      autoload_models_if_admin('LogLines::Email')
    end

    initializer 'mix_log.append_migrations' do |app|
      append_migrations(app)
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'mix_log/action_mailer/base/with_email_record'
    end

    ActiveSupport.on_load(:active_record) do
      ::USER_AGENT_PARSER = UserAgentParser::Parser.new
    end
  end
end
