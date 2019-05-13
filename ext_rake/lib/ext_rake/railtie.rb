module ExtRake
  TASK =      '[TASK]'.freeze
  STEP =      '[STEP]'.freeze
  STARTED =   '[STARTED]'.freeze
  COMPLETED = '[COMPLETED]'.freeze
  FAILED =    '[FAILED]'.freeze
  DONE =      '[DONE]'.freeze
end

class ExtRake::Railtie < Rails::Railtie
  require 'ext_rake/rake/task'

  config.before_configuration do
    require 'ext_rake/rails/application'
  end

  rake_tasks do
    load 'tasks/ext_rake.rake'
  end
end
