require 'mix_rescue/configuration'

autoload :Notice,    'mix_rescue/notice'
autoload :Throttler, 'mix_rescue/throttler'

module MixRescue
  def self.routes
    @routes ||= {
      rescue: '/_rescues/javascripts',
    }
  end

  class Engine < ::Rails::Engine
    require 'rack/attack'
    require 'mix_global'
    require 'mix_log'
    require 'mix_rescue/rack/utils'

    config.before_initialize do |app|
      require 'mix_rescue/action_dispatch/middleware/exception_interceptor'

      autoload_models_if_admin('LogLines::Rescue')

      app.config.middleware.use Rack::Attack
    end

    initializer 'mix_rescue.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        post '/_rescues/javascripts' => 'rescues/javascripts#create', as: :rescues_javascripts
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types['LogLines::Rescue'] = 100
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
