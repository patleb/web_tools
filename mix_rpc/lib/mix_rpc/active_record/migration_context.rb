MonkeyPatch.add{['activerecord', 'lib/active_record/migration.rb', '1d5f05572e7ac1062cfa73a69409ad1b1739c3c8d95c31543aa9e6555024672d']}

ActiveRecord::MigrationContext.class_eval do
  private

  def valid_migration_timestamp?(version)
    true
  end
end
