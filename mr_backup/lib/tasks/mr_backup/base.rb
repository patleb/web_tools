require 'mr_backup/configuration'

module MrBackup
  class Base < ActiveTask::Base
    def with_environment(env)
      super(env) do
        env[:backup_config] = MrBackup.config.instance_variables.each_with_object({}) do |ivar, memo|
          memo[ivar] = MrBackup.config.instance_variable_get(ivar)
        end
        yield(env)
      ensure
        env[:backup_config].each do |ivar, value|
          MrBackup.config.instance_variable_set(ivar, value)
        end
      end
    end
  end
end
