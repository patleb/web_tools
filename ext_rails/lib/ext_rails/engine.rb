require 'routes_lazy_routes'

module ActionService
  autoload :Base, 'ext_rails/action_service/base'
end

module ExtRails
  class Engine < ::Rails::Engine
    require 'active_type'
    require 'date_validator'
    require 'discard'
    require 'http_accept_language'
    require 'monogamy'
    require 'pg'
    require 'stateful_enum'
    require 'rails-i18n'
    if Rails.env.development?
      require 'i18n/debug'
      require 'null_logger'
    end

    require 'sunzistrano/context'
    require 'ext_rails/active_support/abstract_class'
    require 'ext_rails/active_support/core_ext'
    require 'ext_rails/active_support/lazy_load_hooks/autorun'
    require 'ext_rails/active_support/current_attributes'
    require 'ext_rails/active_support/string_inquirer'
    require 'ext_rails/active_support/dependencies/with_nilable_cache'
    require 'ext_rails/configuration'
    require 'ext_rails/http'
    require 'ext_rails/money_rails'
    require 'ext_rails/rack/utils'
    require 'ext_rails/rails/engine'
    require 'ext_rails/rails/initializable/initializer'

    config.before_configuration do |app|
      require 'ext_rails/rails/application'
      require 'ext_rails/rails/initializable/collection'
      require 'ext_rails/pycall'

      app.config.active_record.schema_format = :sql
      app.config.action_view.embed_authenticity_token_in_remote_forms = true
      # app.config.active_record.time_zone_aware_attributes = false
      app.config.i18n.default_locale = :fr
      app.config.i18n.available_locales = [:fr, :en]
      app.config.i18n.fallbacks = [:en]
      # app.config.i18n.fallbacks = true

      if Rails.env.dev_or_test?
        $stdout.sync = true # for Foreman
        host, port = Setting[:default_url_options].values_at(:host, :port)
        app.config.asset_host = "#{host}#{":#{port}" if port}"
        app.config.logger = ActiveSupport::Logger.new(app.config.paths['log'].first, 5)
        app.config.logger.formatter = app.config.log_formatter
      end
    end

    config.before_initialize do |app|
      require 'ext_rails/action_dispatch/middleware/iframe'
      app.config.middleware.use ActionDispatch::IFrame
      app.config.middleware.insert_after ActionDispatch::Static, Rack::Deflater if Rails.env.dev_ngrok?

      %w(libraries tasks).each do |directory|
        ActiveSupport::Dependencies.autoload_paths.delete("#{app.root}/app/#{directory}")
      end

      unless Setting[:timescaledb_enabled]
        Rails.autoloaders.main.ignore("#{root}/app/models/concerns/timescaledb")
        Rails.autoloaders.main.ignore("#{root}/app/models/timescaledb")
      end

      ENV["BACKTRACE"] = true
    end

    initializer 'ext_rails.append_migrations' do |app|
      append_migrations(app)
      append_migrations(app, scope: 'pgunit') if Rails.env.dev_or_test?
      append_migrations(app, scope: 'pgstats') if Setting[:pgstats_enabled]
      append_migrations(app, scope: 'pgrepack') if Setting[:pgrepack_enabled]
      append_migrations(app, scope: 'timescaledb') if Setting[:timescaledb_enabled]
    end

    initializer 'ext_rails.append_routes' do |app|
      app.routes.append do
        match '/' => 'application#healthcheck', via: [:get, :head], as: :base

        match '(/)*not_found', via: :all, to: 'application#render_404', format: false
      end
    end

    initializer 'ext_rails.default_url_options' do |app|
      app.routes.default_url_options = Setting[:default_url_options]
    end

    initializer 'ext_rails.i18n' do
      if defined? I18n::Debug
        unless ExtRails.config.i18n_debug
          I18n::Debug.logger = NullLogger.new
        end
      end

      MoneyRails.configure do |config|
        config.default_currency = :cad
        Money.locale_backend = :i18n
      end
    end

    initializer 'ext_rails.cookies' do |app|
      app.config.session_store :cookie_store, key: "_#{Rails.application.name}_session", expire_after: 2.years
    end

    initializer 'ext_rails.rack_lineprof' do |app|
      if (file = Rails.root.join('tmp/profile.txt')).exist? && (matcher = file.readlines.first&.strip).present?
        require 'ext_rails/rack_lineprof'
        app.middleware.use Rack::Lineprof, profile: matcher
      end
    end

    ActiveSupport.on_load(:action_dispatch_response) do
      require 'ext_rails/action_dispatch/journey/formatter/with_params_fix'
      require 'ext_rails/action_dispatch/routing/url_for/with_only_path'
    end

    ActiveSupport.on_load(:action_controller, run_once: true) do
      require 'ext_rails/action_controller/parameters'
    end

    ActiveSupport.on_load(:action_controller_api) do
      require 'ext_rails/action_controller/api'
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'ext_rails/action_controller/base'
    end

    ActiveSupport.on_load(:active_job) do
      require 'ext_rails/active_job/base'
    end

    ActiveSupport.on_load(:active_record) do
      # TODO https://stackoverflow.com/questions/41399788/use-rails-select-to-add-not-overwrite-selected-attributes
      require 'store_base_sti_class'
      require 'ext_rails/active_type'
      require 'ext_rails/active_record/associations/builder/belongs_to/with_global_id'
      require 'ext_rails/active_record/associations/builder/belongs_to/with_list'
      require 'ext_rails/active_record/connection_adapters/postgresql_adapter'
      require 'ext_rails/active_record/arel'
      require 'ext_rails/active_record/base'
      require 'ext_rails/active_record/migration'
      require 'ext_rails/active_record/reflection/belongs_to_reflection/with_list'
      require 'ext_rails/active_record/relation'
      require 'ext_rails/active_record/tasks/database_tasks/with_single_env'
      require 'ext_rails/active_record/type/json/with_keyword_access'
      require 'ext_rails/active_record/type/encrypted'

      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = Rails.env.test?
    end

    config.to_prepare do
      require 'ext_rails/active_support/lazy_load_hooks/autoload'
      ActiveSupport.autoload_hooks
    end
  end
end
