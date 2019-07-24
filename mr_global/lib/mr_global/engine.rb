require "mr_global/configuration"

module MrGlobal
  class Engine < ::Rails::Engine
    initializer 'mr_global.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
