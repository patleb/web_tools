module MixTask
  STARTED = '[STARTED]'.freeze
  SUCCESS = '[SUCCESS]'.freeze
  FAILURE = '[FAILURE]'.freeze
  STEP    = '[STEP]'.freeze
  CANCEL  = '[CANCEL]'.freeze
  RUNNING = '[RUNNING]'.freeze

  class Engine < Rails::Engine
    require 'mix_rescue'
    require 'mix_task/rake/dsl'
    require 'mix_task/rake/task'

    config.before_configuration do |app|
      require 'mix_task/rails/engine/with_task'
      app.paths.add "app/tasks", glob: "**/*.rake"
    end

    config.before_initialize do
      autoload_models_if_admin(['Task', 'LogLines::Task'])
    end

    initializer 'mix_task.append_migrations' do |app|
      append_migrations(app)
    end

    ActiveSupport.on_load(:active_record) do
      Rails.application.load_tasks
      MixLog.config.available_types['LogLines::Task'] = 120
    end
  end
end
