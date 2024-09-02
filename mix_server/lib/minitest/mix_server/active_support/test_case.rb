ActiveSupport::TestCase.class_eval do
  alias_method :run_without_server_and_logs, :run
  def run(...)
    Server.current
    Log.remove_ivar(:@db_log)
    result = run_without_server_and_logs(...)
    clear_logs unless use_transactional_tests
    result
  end

  def clear_logs
    ActiveRecord::Base.connection.execute <<-SQL.strip_sql
      DELETE FROM "lib_log_unknowns";
      DELETE FROM "lib_log_messages";
      DELETE FROM "lib_log_rollups";
      DELETE FROM "lib_log_lines";
      DELETE FROM "lib_logs";
    SQL
  end
end
