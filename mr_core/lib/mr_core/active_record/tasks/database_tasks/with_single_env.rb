module ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
  extend ActiveSupport::Concern

  class_methods do
    def each_current_configuration(environment)
      environments = [environment]
      # environments << "test" if environment == "development"

      # TODO Rails 6
      ActiveRecord::Base.configurations.to_h.slice(*environments).each do |configuration_environment, configuration|
        next unless configuration["database"]

        yield configuration, configuration_environment
      end
    end
  end
end

ActiveRecord::Tasks::DatabaseTasks.include ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
