require "mix_global/configuration"

module MixGlobal
  class Engine < ::Rails::Engine
    config.before_initialize do
      autoload_models_if_admin('Global')
    end

    initializer 'mix_global.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
