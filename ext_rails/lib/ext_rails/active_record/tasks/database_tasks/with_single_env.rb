MonkeyPatch.add{['activerecord', 'lib/active_record/tasks/database_tasks.rb', '812ab061aa89af88ddde31205765bff277ab7b1960252ce3c3dfd4b240551b04']}

module ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
  extend ActiveSupport::Concern

  class_methods do
    private

    def each_current_configuration(...)
      ENV['SKIP_TEST_DATABASE'] = 'true'
      super
    end

    def initialize_database(db_config)
      with_temporary_pool(db_config) do
        begin
          database_already_initialized = migration_connection_pool.schema_migration.table_exists?
        rescue ActiveRecord::NoDatabaseError
          create(db_config)
          retry
        end

        # unless database_already_initialized
        #   schema_dump_path = schema_dump_path(db_config)
        #   if schema_dump_path && File.exist?(schema_dump_path)
        #     load_schema(db_config, ActiveRecord.schema_format, nil)
        #   end
        # end

        !database_already_initialized
      end
    end
  end
end

ActiveRecord::Tasks::DatabaseTasks.prepend ActiveRecord::Tasks::DatabaseTasks::WithSingleEnv
