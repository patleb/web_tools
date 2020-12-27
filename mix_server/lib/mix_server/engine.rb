require 'ext_ruby'
require 'mix_server/configuration'

module MixServer
  class Engine < ::Rails::Engine
    initializer 'mix_server.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
