require 'ext_ruby'
require 'mix_check/configuration'
require 'pg_query'

module MixCheck
  class Engine < ::Rails::Engine
    config.before_configuration do
      ENV["PGHERO_CONFIG_PATH"] = root.join('config/pghero.yml').to_s
      require 'mix_check/pghero'
    end

    config.before_initialize do
      Rails.autoloaders.main.ignore("#{PgHero::Engine.root}/app/controllers/pg_hero/home_controller")
      Rails.autoloaders.main.ignore("#{PgHero::Engine.root}/app/helpers/pg_hero/home_helper")
    end

    initializer 'mix_check.append_migrations' do |app|
      append_migrations(app)
    end
  end
end
