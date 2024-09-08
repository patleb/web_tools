# frozen_string_literal: true

require 'mix_server'
require 'mix_user'
require 'mix_task/configuration'

module MixTask
  class Engine < Rails::Engine
    require 'mix_task/rake/task/with_log'

    config.before_initialize do
      autoload_models_if_admin(['Task', 'LogLines::Task'])
    end

    initializer 'mix_task.migrations' do |app|
      append_migrations(app)
    end

    ActiveSupport.on_load(:active_record) do
      MixServer::Log.config.available_types['LogLines::Task'] = 170
    end

    ActiveSupport.on_load('Task') do
      Rails.application.load_tasks
    end
  end
end
