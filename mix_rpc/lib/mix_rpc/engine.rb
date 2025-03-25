require 'mix_server'
require 'mix_rpc/configuration'
require 'mix_rpc/routes'

module MixRpc
  class Engine < Rails::Engine
    initializer 'mix_rpc.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_rpc.routes', before: 'ext_rails.routes' do |app|
      app.routes.prepend do
        MixRpc::Routes.draw(self)
      end
    end

    config.to_prepare do
      require 'mix_rpc/active_record/migration_context'
      require 'mix_rpc/rails/generators/with_rpc_schema'
    end
  end
end
