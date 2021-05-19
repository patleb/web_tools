require 'ext_ruby'
require 'mix_server/configuration'

module MixServer
  class Engine < ::Rails::Engine
    require 'mix_server/rake/dsl'
    require 'mix_server/sh'

    config.before_initialize do
      if defined? PhusionPassenger
        PhusionPassenger.on_event(:starting_worker_process) do |_forked|
          Log.worker
        end

        PhusionPassenger.on_event(:stopping_worker_process) do
          Log.worker(stop: true)
        end
      end
    end

    initializer 'mix_server.append_migrations' do |app|
      append_migrations(app)
      append_migrations(app, scope: 'pgrest') if Setting[:pgrest_enabled]
    end

    initializer 'mix_server.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        # TODO
        # https://github.com/ianheggie/health_check
        # https://github.com/lbeder/health-monitor-rails
        # https://github.com/sportngin/okcomputer
        get '_information/ip' => 'servers/information#show_ip', as: :information_ip
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types['LogLines::Worker'] = 150
    end
  end
end
