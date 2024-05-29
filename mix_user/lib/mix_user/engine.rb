# TODO preserve user name after delete to prevent impersonisation
require "mix_user/configuration"

module ActionPolicy
  autoload :Base, 'mix_user/action_policy/base'
end

module MixUser
  class Engine < ::Rails::Engine
    require 'devise'
    # require 'devise-encryptable'
    # require 'devise-i18n'
    require 'mix_template'

    config.before_initialize do
      autoload_models_if_admin('User')
    end

    # initializer 'mix_user.rack_attack' do
      # TODO use Rack::Attack.fail2ban instead
      # Rack::Attack.throttle('sign_in:email', limit: 5, period: 1.day) do |req|
      #   if req.post? && req.path.end_with?('/sign_in')
      #     # TODO log --> then pass to fail2ban
      #     req.params.dig('user', 'email')
      #   end
      # end
    # end

    initializer 'mix_user.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_user.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        devise_for :users
      end
    end

    ActiveSupport.on_load(:active_record) do
      require 'mix_user/active_record/connection_adapters/abstract_adapter'
      require 'mix_user/orm_adapter/active_record'

      if defined? MixJob
        MixJob.configure do |config|
          config.json_attributes[:user] = :string
        end
      end
    end

    config.after_initialize do
      ActiveSupport.on_load(:action_controller_base) do |base|
        next unless (index = base.view_paths.paths.index{ |p| p.to_s.include? '/devise-' })
        paths = base.view_paths.paths.dup
        engines = []
        loop do
          if (engine = paths.pop).nil?
            break
          elsif engine.to_path.include? '/mix_user'
            paths.insert(index, engine)
            break
          end
          engines << engine
        end
        while (engine = engines.pop)
          paths << engine
        end
        base.view_paths = paths
      end
    end
  end
end
