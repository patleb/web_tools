MonkeyPatch.add{['rake', 'lib/rake/backtrace.rb', 'd7717ccd2d224fd94f37d07f8f9333274494486bcfc2a143cc4dc079f14e66c6']}

require 'ext_rails/configuration'
require 'ext_rails/routes'

module ActionController
  autoload :Delegator, 'ext_rails/action_controller/delegator'
end

module ActionView
  autoload :Delegator, 'ext_rails/action_view/delegator'
end

module ActivePresenter
  autoload :Base, 'ext_rails/active_presenter/base'
  autoload :List, 'ext_rails/active_presenter/list'
end

module ActiveTask
  autoload :Base, 'ext_rails/active_task/base'
end

module ExtRails
  ERROR_SEPARATOR = '<br>- '

  class Engine < Rails::Engine
    # require 'active_record_extended'
    require 'date_validator'
    require 'dotiw'
    require 'http_accept_language'
    require 'monogamy'
    require 'optparse'
    require 'pg'
    require 'rounding'
    require 'stateful_enum'
    require 'rails-i18n'
    require 'user_agent_parser'
    if Rails.env.development?
      require 'i18n/debug'
      require 'null_logger'
    end

    require 'sunzistrano'
    require 'ext_rails/active_support/abstract_class'
    require 'ext_rails/active_support/autoload'
    require 'ext_rails/active_support/core_ext'
    require 'ext_rails/active_support/duration'
    require 'ext_rails/active_support/lazy_load_hooks/autorun'
    require 'ext_rails/active_support/current_attributes'
    require 'ext_rails/active_support/dependencies/with_cache'
    require 'ext_rails/geared_pagination'
    require 'ext_rails/money_rails'
    require 'ext_rails/parallel'
    require 'ext_rails/rack/utils'
    require 'ext_rails/rake/dsl'
    require 'ext_rails/rake/task'
    require 'ext_rails/rails/engine'
    require 'ext_rails/rails/initializable/initializer'
    require 'ext_rails/user_agent_parser/user_agent'

    config.before_configuration do |app|
      require 'ext_rails/action_dispatch/routing/mapper/resources'
      require 'ext_rails/rails/application'
      require 'ext_rails/rails/engine/with_task'
      require 'ext_rails/rails/initializable/collection'

      Setting.load
      app.config.action_mailer.delivery_method = :smtp
      app.config.action_mailer.smtp_settings = Setting.smtp
      app.config.action_mailer.default_url_options = Setting[:default_url_options]
      app.config.active_record.schema_format = :sql
      app.config.i18n.default_locale = :fr
      app.config.i18n.available_locales = [:fr, :en]
      app.config.i18n.fallbacks = [:en]
      # app.config.i18n.fallbacks = true
      app.config.time_zone = 'UTC'
      app.paths.add "app/tasks", glob: "**/*.rake"

      $stdout.sync = true

      if Rails.env.local?
        host, port = Setting[:default_url_options].values_at(:host, :port)
        app.config.asset_host = "#{host}#{":#{port}" if port}"
        app.config.logger = ActiveSupport::Logger.new(app.config.paths['log'].first, 5)
        app.config.logger.formatter = app.config.log_formatter
      end
    end

    config.before_initialize do |app|
      app.config.action_mailer.delivery_job = 'LibMailerJob'

      %w(app/libraries app/tasks).each do |directory|
        ActiveSupport::Dependencies.autoload_paths.delete("#{app.root}/#{directory}")
      end
    end

    initializer 'ext_rails.migrations' do |app|
      append_migrations(app)
      append_migrations(app, scope: 'aggs_for_vecs')      if Setting[:aggs_for_vecs]
      append_migrations(app, scope: 'pg_repack')          if Setting[:pg_repack]
      append_migrations(app, scope: 'pg_stat_statements') if Setting[:pg_stat_statements]
      append_migrations(app, scope: 'pgunit') if Rails.env.local?
    end

    initializer 'ext_rails.routes' do |app|
      app.routes.append do
        match '/' => 'lib_api#healthcheck', via: [:get, :head], as: :base

        get '/test/:name' => 'ext_rails/test#show', as: :test if Rails.env.test?

        get '/favicon.ico', to: -> (_) { [404, {}, ['']] } unless ExtRails.config.favicon_ico
        get '/.well-known/appspecific/com.chrome.devtools.json', to: -> (_) { [404, {}, ['']] }

        match '(/)*not_found', via: :all, to: 'lib#render_404', format: false
      end
    end

    initializer 'ext_rails.default_url_options' do |app|
      app.routes.default_url_options = Setting[:default_url_options]
    end

    initializer 'ext_rails.i18n' do |app|
      require 'ext_rails/active_support/i18n'

      (app.config.i18n.available_locales & %i(es fr it kk nb pt_br tr)).each do |locale|
        require "ext_rails/active_support/inflections/#{locale}"
      end

      I18n::Backend::Simple.prepend I18n::Backend::Memoize
      I18n::Debug.logger = NullLogger.new if defined?(I18n::Debug) && !ExtRails.config.i18n_debug

      MoneyRails.configure do |config|
        config.default_currency = :cad
        Money.locale_backend = :i18n
      end
    end

    initializer 'ext_rails.cookies' do |app|
      app.config.session_store :cookie_store, key: "_#{Rails.application.name}_session", expire_after: 400.days
    end

    initializer 'ext_rails.rack_middlewares' do |app|
      if (file = Rails.root.join('tmp/profile.txt')).exist? && (matcher = file.readlines.first&.strip).present?
        require 'ext_rails/rack_lineprof'
        app.middleware.use Rack::Lineprof, profile: matcher
      end
      app.middleware.use Rack::ContentLength if Rails.env.local?
    end

    config.after_initialize do
      ActionView::Helpers::FormTagHelper.embed_authenticity_token_in_remote_forms = ExtRails.config.css_only_support
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

    ActiveSupport.on_load(:action_mailer) do
      require 'ext_rails/action_mailer/base'
      require 'ext_rails/action_mailer/log_subscriber/with_quiet_info'
      next if Rails.env.production?
      require 'ext_rails/action_mailer/interceptors/email_prefixer'
      require 'ext_rails/action_mailer/interceptors/forward_all_to'
    end

    ActiveSupport.on_load(:action_view) do
      require 'ext_rails/action_view/helpers/asset_url_helper/with_memoize'
      require 'ext_rails/action_view/helpers/tag_helper/tag_builder/with_data_option'
      require 'ext_rails/action_view/helpers/capture_helper'
      require 'ext_rails/action_view/helpers/output_safety_helper'
      require 'ext_rails/action_view/helpers/tag_helper'
      require 'ext_rails/action_view/helpers/text_helper'
      require 'ext_rails/action_view/template_renderer/with_virtual_path'
    end

    ActiveSupport.on_load(:active_job) do
      require 'ext_rails/active_job/base'
    end

    ActiveSupport.on_load(:virtual_record) do
      require 'ext_rails/active_type'
    end

    ActiveSupport.on_load(:active_record) do
      require 'ext_rails/active_type'
      require 'ext_rails/active_record/store_base_sti_class'
      require 'ext_rails/active_record/associations/builder/belongs_to/with_global_id'
      require 'ext_rails/active_record/associations/builder/belongs_to/with_list'
      require 'ext_rails/active_record/associations/builder/has_many/with_discard'
      require 'ext_rails/active_record/associations/builder/has_one/with_discard'
      require 'ext_rails/active_record/connection_adapters/postgresql_adapter'
      require 'ext_rails/active_record/arel'
      require 'ext_rails/active_record/base'
      require 'ext_rails/active_record/enum/with_keyword_access'
      require 'ext_rails/active_record/migration'
      require 'ext_rails/active_record/reflection/belongs_to_reflection/with_list'
      require 'ext_rails/active_record/reflection/has_many_reflection/with_discard'
      require 'ext_rails/active_record/reflection/has_one_reflection/with_discard'
      require 'ext_rails/active_record/relation'
      require 'ext_rails/active_record/tasks/database_tasks/with_single_env'
      require 'ext_rails/active_record/type/json/with_keyword_access'
      require 'ext_rails/active_record/type/encrypted'
      ::USER_AGENT_PARSER = UserAgentParser::Parser.new
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = Rails.env.test?
    end

    ActiveSupport.on_load(:active_task) do
      require 'ext_rails/active_task/as_parallel'
    end

    config.to_prepare do
      require 'ext_rails/active_support/lazy_load_hooks/autoload'
      ActiveSupport.autoload_hooks
    end
  end
end
