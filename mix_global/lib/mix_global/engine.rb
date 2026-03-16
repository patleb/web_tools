require "mix_global/configuration"

module MixGlobal
  class Engine < Rails::Engine
    initializer 'mix_global.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_global.backup' do
      ExtRails.config.temporary_tables << 'lib_globals'
    end

    initializer 'mix_global.admin' do
      MixAdmin.configure do |config|
        config.included_models << 'Global'
      end
    end
  end
end
