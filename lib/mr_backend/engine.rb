require 'mr_backend/rails/env'

module ActionService
  autoload :Base, 'mr_backend/action_service/base'
end

module MrBackend
  class Engine < ::Rails::Engine
    require 'active_type'
    require 'baby_squeel' # https://github.com/activerecord-hackery/polyamorous/issues/26
    require 'date_validator'
    require 'http_accept_language'
    require 'i18n/debug' if Rails.env.development?
    require 'kaminari'
    require 'monogamy'
    require 'null_logger' if Rails.env.development?
    require 'pg'
    require 'rails-i18n'
    require 'store_base_sti_class'
    require 'vmstat'
    require 'mr_backend/action_mailer/smtp_settings'
    require 'mr_backend/active_support/core_ext'
    require 'mr_backend/active_support/current_attributes'
    require 'mr_backend/active_support/dependencies/with_nilable_cache'
    require 'mr_backend/money_rails'
    require 'mr_backend/rails/engine'

    require 'ext_capistrano'
    # require 'ext_minitest'
    require 'ext_rake'
    require 'ext_ruby'
    require 'ext_sql'
    # require 'ext_whenever'
    require 'mr_backup'
    require 'mr_global'
    require 'mr_notifier'
    require 'mr_setting'
    require 'mr_rescue'
    require 'mr_template'
    require 'mr_throttler'
    # require 'sun_cap'
    # require 'sunzistrano'

    require 'mr_backend/configuration'

    config.before_configuration do |app|
      app.config.cache_store = :global_store if defined? MrGlobal
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
        app.config.action_mailer.default_url_options = -> { { host: Setting[:server] } }
      end

      if (file = Rails.root.join('tmp/console.txt')).exist? && (ips = file.read.split("\n").reject(&:blank?)).any?
        require 'web-console'
        app.config.web_console.whitelisted_ips = ips
        app.config.web_console.development_only = false
      end
    end

    config.before_initialize do |app|
      require 'mr_backend/action_dispatch/middleware/iframe'
      app.config.middleware.use ActionDispatch::IFrame
      app.config.middleware.insert_after ActionDispatch::Static, Rack::Deflater if Rails::Env.dev_ngrok?
    end

    initializer 'mr_backend.append_migrations' do |app|
      append_migrations(app)
      append_api_migrations(app) if Setting[:pgrest_enabled]
    end

    initializer 'mr_backend.append_routes' do |app|
      app.routes.append do
        resources :javascript_rescues, only: [:create]

        match '/' => 'application#healthcheck', via: [:get, :head], as: :base

        match '*not_found', via: :all, to: 'application#render_404', format: false
      end
    end

    initializer 'mr_backend.default_url_options', before: 'action_mailer.set_configs' do |app|
      default_url_options = app.config.action_mailer.default_url_options
      if default_url_options.respond_to? :call
        app.config.action_mailer.default_url_options = default_url_options.call
      end
      app.routes.default_url_options = app.config.action_mailer.default_url_options
    end

    initializer 'mr_backend.i18n' do
      if defined? I18n::Debug
        unless MrBackend.config.i18n_debug
          I18n::Debug.logger = NullLogger.new
        end
      end

      MoneyRails.configure do |config|
        config.default_currency = :cad
        Money.locale_backend = :i18n
      end
    end

    initializer 'mr_backend.rack_lineprof' do |app|
      if (file = Rails.root.join('tmp/profile.txt')).exist? && (matcher = file.readlines.first&.strip).present?
        require 'mr_backend/rack_lineprof'
        app.middleware.use Rack::Lineprof, profile: matcher
      end
    end

    ActiveSupport.on_load(:action_controller, run_once: true) do
      require 'mr_backend/action_dispatch/routing/url_for/with_only_path'
      require 'mr_backend/action_controller/parameters'
      require 'mr_backend/action_controller/with_status'
      require 'mr_backend/action_controller/with_errors'
      require 'mr_backend/action_controller/with_logger'
    end

    ActiveSupport.on_load(:action_controller) do |base|
      base.include ActionController::WithLogger
    end

    ActiveSupport.on_load(:action_controller_api) do
      require 'mr_backend/action_controller/api'
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'mr_backend/action_controller/base'
    end

    ActiveSupport.on_load(:active_record) do
      require 'rails_select_on_includes'
      require 'mr_backend/active_type'
      require 'mr_backend/active_record/connection_adapters/postgresql_adapter'
      require 'mr_backend/active_record/base'
      require 'mr_backend/active_record/relation'
      require 'mr_backend/active_record/tasks/database_tasks/with_single_env'
    end

    ActiveSupport.on_load(:action_mailer) do
      require 'mr_backend/action_mailer/base'
      require 'mr_backend/action_mailer/log_subscriber/with_quiet_info'
    end
  end
end
