require 'mr_core/rails/env'

module ActionService
  autoload :Base, 'mr_core/action_service/base'
end

module MrCore
  class Engine < ::Rails::Engine
    require 'active_type'
    require 'date_validator'
    require 'http_accept_language'
    require 'i18n/debug' if Rails.env.development?
    require 'monogamy'
    require 'null_logger' if Rails.env.development?
    require 'pg'
    require 'rails-i18n'
    require 'vmstat'

    require 'mr_core/action_mailer/smtp_settings'
    require 'mr_core/active_support/core_ext'
    require 'mr_core/active_support/current_attributes'
    require 'mr_core/active_support/dependencies/with_nilable_cache'
    require 'mr_core/configuration'
    require 'mr_core/money_rails'
    require 'mr_core/pycall/pyobject_wrapper' if Gem.loaded_specs['pycall']
    require 'mr_core/rails/engine'
    require 'mr_core/rake/dsl'
    require 'mr_core/sh'

    config.before_configuration do |app|
      if defined? MrGlobal
        app.config.active_record.cache_versioning = false
        app.config.cache_store = :global_store
      end
      app.config.active_record.schema_format = :sql
      app.config.action_mailer.delivery_method = :smtp
      app.config.action_mailer.smtp_settings = ActionMailer::SmtpSettings.new(Setting)
      app.config.action_view.embed_authenticity_token_in_remote_forms = true
      # app.config.active_record.time_zone_aware_attributes = false
      app.config.i18n.default_locale = :fr
      app.config.i18n.available_locales = [:fr, :en]
      app.config.i18n.fallbacks = [:en]
      # app.config.i18n.fallbacks = true

      if Rails::Env.dev_or_test?
        $stdout.sync = true # for Foreman
        url_options = Rails::Env.dev_or_test_url_options
        host, port = url_options.values_at(:host, :port)
        app.config.action_controller.asset_host = "#{host}#{":#{port}" if port}"
        app.config.action_mailer.asset_host = app.config.action_controller.asset_host
        app.config.action_mailer.default_url_options = url_options
        app.config.logger = ActiveSupport::Logger.new(app.config.paths['log'].first, 5)
        app.config.logger.formatter = app.config.log_formatter
      else
        app.config.action_mailer.default_url_options = -> { { host: Setting[:server_host] } }
      end

      if (file = Rails.root.join('tmp/console.txt')).exist? && (ips = file.read.split("\n").reject(&:blank?)).any?
        require 'web-console'
        app.config.web_console.whitelisted_ips = ips
        app.config.web_console.development_only = false
      end
    end

    config.before_initialize do |app|
      require 'mr_core/action_dispatch/middleware/iframe'
      app.config.middleware.use ActionDispatch::IFrame
      app.config.middleware.insert_after ActionDispatch::Static, Rack::Deflater if Rails::Env.dev_ngrok?
    end

    initializer 'mr_core.append_migrations' do |app|
      append_migrations(app)
      append_api_migrations(app) if Setting[:pgrest_enabled]
    end

    initializer 'mr_core.append_routes' do |app|
      app.routes.append do
        resources :javascript_rescues, only: [:create]

        match '/' => 'application#healthcheck', via: [:get, :head], as: :base

        match '*not_found', via: :all, to: 'application#render_404', format: false
      end
    end

    initializer 'mr_core.default_url_options', before: 'action_mailer.set_configs' do |app|
      default_url_options = app.config.action_mailer.default_url_options
      if default_url_options.respond_to? :call
        app.config.action_mailer.default_url_options = default_url_options.call
      end
      app.routes.default_url_options = app.config.action_mailer.default_url_options
    end

    initializer 'mr_core.i18n' do
      if defined? I18n::Debug
        unless MrCore.config.i18n_debug
          I18n::Debug.logger = NullLogger.new
        end
      end

      MoneyRails.configure do |config|
        config.default_currency = :cad
        Money.locale_backend = :i18n
      end
    end

    initializer 'mr_core.rack_lineprof' do |app|
      if (file = Rails.root.join('tmp/profile.txt')).exist? && (matcher = file.readlines.first&.strip).present?
        require 'mr_core/rack_lineprof'
        app.middleware.use Rack::Lineprof, profile: matcher
      end
    end

    ActiveSupport.on_load(:action_controller, run_once: true) do
      require 'mr_core/action_dispatch/routing/url_for/with_only_path'
      require 'mr_core/action_controller/parameters'
      require 'mr_core/action_controller/with_status'
      require 'mr_core/action_controller/with_errors'
      require 'mr_core/action_controller/with_logger'
    end

    ActiveSupport.on_load(:action_controller) do |base|
      base.include ActionController::WithLogger
    end

    ActiveSupport.on_load(:action_controller_api) do
      require 'mr_core/action_controller/api'
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'mr_core/action_controller/base'
    end

    ActiveSupport.on_load(:active_record) do
      require 'arel_extensions'
      require 'rails_select_on_includes'
      require 'mr_core/active_type'
      require 'mr_core/active_record/store_base_sti_class'
      require 'mr_core/active_record/connection_adapters/postgresql_adapter'
      require 'mr_core/active_record/base'
      require 'mr_core/active_record/relation'
      require 'mr_core/active_record/tasks/database_tasks/with_single_env'
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'mr_core/action_mailer/base'
      require 'mr_core/action_mailer/log_subscriber/with_quiet_info'
    end
  end
end
