ActiveSupport::TestCase.class_eval do
  delete_tables.concat(%w(lib_log_unknowns lib_log_messages lib_log_rollups lib_log_lines lib_logs))

  alias_method :run_without_server_and_logs, :run
  def run(...)
    Server.current
    Log.remove_ivar(:@db_log)
    run_without_server_and_logs(...)
  end
end
