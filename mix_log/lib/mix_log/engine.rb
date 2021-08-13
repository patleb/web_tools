require 'ext_ruby'
require 'mix_log/configuration'

module MixLog
  class Engine < ::Rails::Engine
    require 'user_agent_parser'
    require 'mix_log/user_agent_parser/user_agent'

    initializer 'mix_log.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_log.db_partitions' do
      ExtRails.config.db_partitions[:lib_log_lines] = :week
    end

    ActiveSupport.on_load(:active_record) do
      ::USER_AGENT_PARSER = UserAgentParser::Parser.new
    end
  end
end
