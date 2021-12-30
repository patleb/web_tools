require 'ext_ruby'
require 'mix_rpc/configuration'

module MixRpc
  def self.routes
    @routes ||= {
      rpc: '/rpc/functions/__ID__',
    }
  end

  class Engine < ::Rails::Engine
    initializer 'mix_rpc.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_rpc.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        post '/rpc/functions/:id' => 'rpc/functions#call', as: :rpc_functions
      end
    end

    config.to_prepare do
      require 'mix_rpc/rails/generators/with_rpc_schema'
    end
  end
end
