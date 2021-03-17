module ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
  extend ActiveSupport::Concern

  class_methods do
    def each_current_configuration(...)
      ENV['SKIP_TEST_DATABASE'] = true
      super
    end
  end
end

ActiveRecord::Tasks::DatabaseTasks.prepend ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
