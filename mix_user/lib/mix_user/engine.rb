require "mix_user/configuration"

module ActionPolicy
  autoload :Base, 'mix_user/action_policy/base'
end

module MixUser
  class Engine < ::Rails::Engine
    require 'devise'
    # require 'devise-encryptable'
    require 'devise-i18n'
    require 'pundit'
    require 'mix_core'

    config.before_initialize do
      unless defined? MixAdmin
        Rails.autoloaders.main.ignore("#{root}/app/models/user_admin.rb")
      end
    end

    initializer 'mix_user.rack_attack' do
      # TODO use Rack::Attack.fail2ban instead
      Rack::Attack.throttle('sign_in:email', limit: 5, period: 1.day) do |req|
        if req.post? && req.path.end_with?('/sign_in')
          # TODO log --> then pass to fail2ban
          req.params.dig('user', 'email')
        end
      end
    end

    initializer 'mix_user.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_user.prepend_routes', before: 'mix_core.append_routes' do |app|
      app.routes.prepend do
        devise_for :users
      end
    end

    ActiveSupport.on_load(:active_record) do
      require 'mix_user/active_record/connection_adapters/abstract_adapter'
      require 'mix_user/orm_adapter/active_record'
      require 'mix_user/pundit/policy_finder'

      MixBatch.configure do |config|
        config.json_attributes.merge!(
          user: :string
        )
      end if defined? MixBatch
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'mix_user/action_controller/base/with_user_helpers'
    end

    config.after_initialize do
      ActiveSupport.on_load(:action_controller_base) do |base|
        index = base.view_paths.paths.index{ |p| p.to_s.include? '/devise-' }
        engines = []
        loop do
          if (engine = base.view_paths.pop).nil?
            break
          elsif engine.to_path.include? '/mix_user'
            base.view_paths.insert(index, engine)
            break
          end
          engines << engine
        end
        while (engine = engines.pop)
          base.view_paths << engine
        end
      end
    end
  end
end
