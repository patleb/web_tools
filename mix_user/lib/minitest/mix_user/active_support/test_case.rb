ActiveSupport::TestCase.class_eval do
  alias_method :run_without_clear_users, :run
  def run(...)
    result = run_without_clear_users(...)
    clear_users unless use_transactional_tests
    result
  end

  def clear_users
    ActiveRecord::Base.connection.execute <<-SQL.strip_sql
      DELETE FROM "lib_user_sessions";
      DELETE FROM "lib_users";
    SQL
  end
end
