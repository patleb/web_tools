require "mix_global/configuration"

module MixGlobal
  class Engine < ::Rails::Engine
    config.before_configuration do |app|
      # TODO doesn't work, must be added to Rails.root/config/application.rb
      app.config.active_record.cache_versioning = false
      app.config.cache_store = :global_store
    end

    config.before_initialize do
      autoload_models_if_admin('Global')
    end

    initializer 'mix_global.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
