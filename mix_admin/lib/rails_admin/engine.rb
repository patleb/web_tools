require 'rails_admin/routes'

module RailsAdmin
  extend Routes

  NAMESPACE_SEPARATOR = '-'

  class Engine < Rails::Engine
    isolate_namespace RailsAdmin

    require 'rails_admin-i18n'
    require 'amoeba'
    require 'kaminari'
    require 'mix_global'
    require 'mix_user'

    config.before_configuration do
      require 'rails_admin/active_model/name/with_admin'
      require 'rails_admin/active_support/concern/with_admin'
      require 'rails_admin/active_support/core_ext/module/autoload'
      require 'rails_admin/active_support/core_ext/numeric/conversions'
      require 'rails_admin/active_support/core_ext/object/full_symbolize'
      require 'rails_admin/active_support/core_ext/array'
      require 'rails_admin/active_support/core_ext/string'
      require 'rails_admin/ooor/base/with_admin' if defined? Ooor::Base
    end

    initializer 'rails_admin.reload_config' do
      if Rails.application.config.cache_classes
        ActiveSupport::Reloader.before_class_unload do
          RailsAdmin.config.reset_all_models
        end
      end
    end

    initializer 'rails_admin.excluded_models' do
      MixCore.config.excluded_models.merge %w(
        RailsAdmin::Choose
      )
    end

    # TODO https://github.com/sferik/rails_admin/issues/2726#issuecomment-387521401
    # TODO still need to not eager_load all models on startup which makes autoload_hooks a bit useless

    # Check for required middlewares, users may forget to use them in Rails API mode
    config.after_initialize do |app|
      has_session_store = app.config.middleware.to_a.any? do |m|
        m.klass.try(:<=, ActionDispatch::Session::AbstractStore) || m.klass.name =~ /^ActionDispatch::Session::/
      end
      loaded = app.config.middleware.to_a.map(&:name)
      required = %w(ActionDispatch::Cookies ActionDispatch::Flash Rack::MethodOverride)
      missing = required - loaded
      unless missing.empty? && has_session_store
        configs = missing.map{ |m| "config.middleware.use #{m}" }
        unless has_session_store
          configs << "config.middleware.use #{app.config.session_store.try(:name) || 'ActionDispatch::Session::CookieStore'}, #{app.config.session_options}"
        end
        raise <<~EOM
          Required middlewares for RailsAdmin are not added
          To fix this, add

            #{configs.join("\n  ")}

          to config/application.rb.
        EOM
      end
    end
  end
end
