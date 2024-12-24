# frozen_string_literal: true

require 'mix_server'
require 'mix_user'
require 'mix_task/configuration'

module MixTask
  class Engine < Rails::Engine
    require 'mix_task/rake/task/with_log'

    initializer 'mix_task.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_task.admin' do
      MixAdmin.configure do |config|
        config.included_models << 'Task'
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixServer::Log.config.available_types['LogLines::Task'] = 170
    end
  end
end
