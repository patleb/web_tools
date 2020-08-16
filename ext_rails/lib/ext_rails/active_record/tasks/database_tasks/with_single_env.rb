module ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
  extend ActiveSupport::Concern

  class_methods do
    def each_current_configuration(environment, spec_name = nil)
      environments = [environment]
      # environments << "test" if environment == "development"

      # TODO Rails 6 db config not a hash anymore
      environments.each do |env|
        ActiveRecord::Base.configurations.configs_for(env_name: env).each do |db_config|
          next if spec_name && spec_name != db_config.spec_name

          yield db_config.config, db_config.spec_name, env
        end
      end
    end
  end
end

ActiveRecord::Tasks::DatabaseTasks.include ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
