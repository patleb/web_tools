require "mix_global/configuration"

module MixGlobal
  class Engine < ::Rails::Engine
    initializer 'mix_global.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
