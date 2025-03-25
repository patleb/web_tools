require 'ext_rails'
require 'mix_server/configuration'
require 'mix_server/routes'

autoload :Notice,    'mix_server/notice'
autoload :Throttler, 'mix_server/throttler'

module MixServer
  class Engine < Rails::Engine
    require 'pg_query'
    require 'mix_global'
    require 'mix_server/rack/utils'
    require 'mix_server/rake/dsl'
    require 'mix_server/sh'

    config.before_configuration do
      ENV["PGHERO_CONFIG_PATH"] = root.join('config/pghero.yml').to_s
      require 'mix_server/pghero'
    end

    config.before_initialize do
      Rails.autoloaders.main.ignore("#{PgHero::Engine.root}/app/controllers/pg_hero/home_controller")
      Rails.autoloaders.main.ignore("#{PgHero::Engine.root}/app/helpers/pg_hero/home_helper")

      if defined? PhusionPassenger
        PhusionPassenger.on_event(:starting_worker_process) do |_forked|
          Log.worker
        end

        PhusionPassenger.on_event(:stopping_worker_process) do
          Log.worker(stop: true)
        end
      end
    end

    initializer 'mix_server.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_server.db_partitions' do
      ExtRails.config.db_partitions[:lib_log_lines] = :week
    end

    initializer 'mix_server.routes', before: 'ext_rails.routes' do |app|
      app.routes.prepend do
        MixServer::Routes.draw(self)
      end
    end

    initializer 'mix_server.admin' do
      MixAdmin.configure do |config|
        config.included_models += %w(
          LogLines::Email
          LogLines::Rescue
        )
      end
    end

    ActiveSupport.on_load(:action_controller, run_once: true) do
      require 'mix_server/action_dispatch/middleware/exception_interceptor'
    end

    ActiveSupport.on_load(:action_controller_api) do
      require 'mix_server/action_controller/api'
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'mix_server/action_controller/base'
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'mix_server/action_mailer/base/with_email_record'
    end
  end
end
