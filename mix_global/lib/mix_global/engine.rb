require "mix_global/configuration"

module MixGlobal
  class Engine < ::Rails::Engine
    initializer 'mix_global.migrations' do |app|
      append_migrations(app)
    end
  end
end
