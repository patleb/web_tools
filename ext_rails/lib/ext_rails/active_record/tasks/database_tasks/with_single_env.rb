MonkeyPatch.add{['activerecord', 'lib/active_record/tasks/database_tasks.rb', '812ab061aa89af88ddde31205765bff277ab7b1960252ce3c3dfd4b240551b04']}

module ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
  extend ActiveSupport::Concern

  class_methods do
    def each_current_configuration(...)
      ENV['SKIP_TEST_DATABASE'] = 'true'
      super
    end
  end
end

ActiveRecord::Tasks::DatabaseTasks.prepend ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
