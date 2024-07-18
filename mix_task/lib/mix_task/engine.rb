# frozen_string_literal: true

require 'ext_rails'
require 'mix_task/configuration'

module MixTask
  class Engine < Rails::Engine
    require 'mix_task/rake/task/with_log'

    config.before_initialize do
      autoload_models_if_admin(['Task', 'LogLines::Task'])
    end

    initializer 'mix_task.append_migrations' do |app|
      append_migrations(app)
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types['LogLines::Task'] = 120
    end

    ActiveSupport.on_load('Task') do
      Rails.application.load_tasks
    end
  end
end
