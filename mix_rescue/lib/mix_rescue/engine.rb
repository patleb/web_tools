require 'mix_rescue/configuration'

autoload :Notice,    'mix_rescue/notice'
autoload :Throttler, 'mix_rescue/throttler'

module MixRescue
  def self.js_routes
    @js_routes ||= {
      rescue: '/rescues/javascripts',
    }
  end

  class Engine < ::Rails::Engine
    require 'rack/attack'
    require 'mix_global'

    config.before_initialize do |app|
      autoload_models_if_admin('Rescue')

      app.config.middleware.use Rack::Attack
    end

    initializer 'mix_rescue.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_rescue.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        namespace :rescues do
          resources :javascripts, only: [:create]
        end
      end
    end

    ActiveSupport.on_load(:action_controller, run_once: true) do
      require 'mix_rescue/action_controller/with_status'
      require 'mix_rescue/action_controller/with_errors'
      require 'mix_rescue/action_controller/with_logger'
    end

    ActiveSupport.on_load(:action_controller) do |base|
      base.include ActionController::WithLogger
    end

    ActiveSupport.on_load(:action_controller_api) do
      require 'mix_rescue/action_controller/api/with_rescue'
    end

    ActiveSupport.on_load(:action_controller_base) do
      require 'mix_rescue/action_controller/base/with_rescue'
    end
  end
end
