module ExtRake
  TASK =      '[TASK]'.freeze
  STEP =      '[STEP]'.freeze
  STARTED =   '[STARTED]'.freeze
  COMPLETED = '[COMPLETED]'.freeze
  FAILED =    '[FAILED]'.freeze
  DONE =      '[DONE]'.freeze
  CANCEL =    '[CANCEL]'.freeze

  class Railtie < Rails::Engine
    require 'mr_rescue'
    require 'ext_rake/rake/dsl'
    require 'ext_rake/rake/task'

    config.before_configuration do
      require 'ext_rake/rails/application'
    end
  end
end
