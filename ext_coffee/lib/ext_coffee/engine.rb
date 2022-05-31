require 'ext_ruby'
require 'ext_coffee/configuration'

module ExtCoffee
  class Engine < ::Rails::Engine
    require 'ext_coffee/turbolinks'

    if Rails.env.development?
      paths['app/controllers'] = 'lib/controllers'
      paths['app/views'] = 'lib/views'
      config.autoload_paths << root.join('lib/controllers')
      config.autoload_paths << root.join('lib/views')
    end

    config.before_initialize do |app|
      app.config.content_security_policy_nonce_generator = -> (request) do
        if request.env['HTTP_TURBOLINKS_REFERRER'].present?
          request.env['HTTP_X_TURBOLINKS_NONCE']
        else
          SecureRandom.base64(16)
        end
      end
    end

    initializer 'ext_coffee.prepend_routes', before: 'ext_rails.append_routes' do |app|
      if Rails.env.development?
        app.routes.prepend do
          get '/favicon.ico', to: -> (_) { [404, {}, ['']] }

          scope path: '/coffee', controller: 'coffee' do
            get '/' => :index
            get '/new' => :new
            post '/new' => :create
            scope path: '/:id' do
              get '/' => :show
              get '/edit' => :edit
              post '/edit' => :update
              get '/delete' => :delete
              post '/delete' => :destroy
            end
          end
        end
      end
    end

    ActiveSupport.on_load(:action_controller_base) do |base|
      base.include Turbolinks::Controller

      ActionDispatch::Assertions.include Turbolinks::Assertions
    end
  end
end
