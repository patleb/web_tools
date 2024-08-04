MonkeyPatch.add{['activerecord', 'lib/active_record/tasks/database_tasks.rb', '746badf7f6b3740979c82001c00b5c5d8a9161fdcd83d3a3cb158f3a3d7e8441']}

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
