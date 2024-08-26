# frozen_string_literal: true

require 'ext_rails'
require 'mix_user/configuration'
require 'mix_user/routes'

module ActionPolicy
  autoload :Base, 'mix_user/action_policy/base'
end

module MixUser
  class Engine < ::Rails::Engine
    config.before_initialize do
      autoload_models_if_admin('User')
    end

    initializer 'mix_user.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_user.prepend_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.prepend do
        MixUser::Routes.draw(self)
      end
    end

    ActiveSupport.on_load(:active_record) do
      require 'mix_user/active_record/connection_adapters/abstract_adapter'

      if defined? MixJob
        MixJob.configure do |config|
          config.json_attributes[:user] = :string
        end
      end
    end
  end
end
