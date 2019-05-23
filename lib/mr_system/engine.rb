module MrSystem
  class Engine < ::Rails::Engine
    require 'ext_capistrano'
    # require 'ext_minitest'
    require 'ext_rake'
    require 'ext_ruby'
    require 'ext_sql'
    # require 'ext_whenever'
    require 'mr_backup'
    require 'mr_notifier'
    require 'mr_secret'
    # require 'sun_cap'
    # require 'sunzistrano'

    require 'mr_system/configuration'

    config.before_configuration do |app|
      require 'mr_system/rails/engine'

      app.config.active_record.schema_format = :sql
    end

    initializer 'ext_sql.append_migrations' do |app|
      append_migrations(app) if MrSystem.config.with_pgrest
    end
  end
end
