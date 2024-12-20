MonkeyPatch.add{['activerecord', 'lib/active_record/tasks/database_tasks.rb', '07b20ece083de6feed23baad3c08d3dafee54bf86ef559a685ef58917c79253a']}

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
