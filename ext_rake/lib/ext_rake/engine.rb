module ExtRake
  TASK =      '[TASK]'.freeze
  STEP =      '[STEP]'.freeze
  STARTED =   '[STARTED]'.freeze
  COMPLETED = '[COMPLETED]'.freeze
  FAILED =    '[FAILED]'.freeze
  DONE =      '[DONE]'.freeze
  CANCEL =    '[CANCEL]'.freeze

  class Engine < Rails::Engine
    require 'mix_rescue'
    require 'ext_rake/rake/dsl'
    require 'ext_rake/rake/task'

    ActiveSupport.on_load(:active_record) do
      MixRescue.config.available_types.merge! 'Rescues::Rake' => 20
    end
  end
end
