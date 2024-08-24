MonkeyPatch.add{['railties', 'lib/rails/generators/migration.rb', 'd66bf61070ce3445c8eed7ffe1e3d0860f8cce0507144e4830317a6dc9ac43e6']}

require 'ext_ruby'
require 'mix_rpc/configuration'

module MixRpc
  class Engine < ::Rails::Engine
    require 'mix_rpc/routes'

    initializer 'mix_rpc.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_rpc.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        MixRpc::Routes.draw(self)
      end
    end

    config.to_prepare do
      require 'mix_rpc/rails/generators/with_rpc_schema'
    end
  end
end
