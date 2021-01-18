module MixTask
  STARTED = '[STARTED]'.freeze
  SUCCESS = '[SUCCESS]'.freeze
  FAILURE = '[FAILURE]'.freeze
  STEP    = '[STEP]'.freeze
  CANCEL  = '[CANCEL]'.freeze

  class Engine < Rails::Engine
    require 'mix_rescue'
    require 'mix_task/rake/dsl'
    require 'mix_task/rake/task'

    config.before_initialize do
      autoload_models_if_admin('LogLines::Task')
    end

    ActiveSupport.on_load(:active_record) do
      MixLog.config.available_types['LogLines::Task'] = 120
    end
  end
end
