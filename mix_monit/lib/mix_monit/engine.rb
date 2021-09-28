require 'ext_ruby'
require 'mix_monit/configuration'
require 'pg_query'

module MixMonit
  class Engine < ::Rails::Engine
    config.before_configuration do
      ENV["PGHERO_CONFIG_PATH"] = root.join('config/pghero.yml').to_s
      require 'mix_monit/pghero'
    end

    config.before_initialize do
      Rails.autoloaders.main.ignore("#{PgHero::Engine.root}/app/controllers/pg_hero/home_controller")
      Rails.autoloaders.main.ignore("#{PgHero::Engine.root}/app/helpers/pg_hero/home_helper")
    end

    initializer 'mix_monit.append_migrations' do |app|
      append_migrations(app)
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types.merge!(
        'LogLines::Database' => 140,
        'LogLines::Host' => 142,
      )
      MixLog.config.available_rollups.merge!(
        'LogRollups::Database' => 100,
        'LogRollups::Host' => 102,
      )
    end
  end
end
