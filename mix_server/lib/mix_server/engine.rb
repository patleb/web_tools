require 'ext_ruby'
require 'user_agent_parser'
require 'mix_server/configuration'
require 'mix_server/user_agent_parser/user_agent'

module MixServer
  class Engine < ::Rails::Engine
    initializer 'mix_server.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
