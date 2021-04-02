require 'ext_ruby'
require 'mix_rpc/configuration'

module MixRpc
  class Engine < ::Rails::Engine
    initializer 'mix_rpc.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_rpc.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        post '/rpc/functions/:id' => 'rpc/functions#call', as: :rpc_functions
      end
    end
  end
end
