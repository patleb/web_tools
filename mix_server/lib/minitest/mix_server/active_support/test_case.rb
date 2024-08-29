ActiveSupport::TestCase.class_eval do
  alias_method :run_without_server_and_logs, :run
  def run(...)
    Server.current
    result = run_without_server_and_logs(...)
    clear_logs unless use_transactional_tests
    result
  end

  def clear_logs
    LogUnknown.delete_all
    LogLine.delete_all
    LogMessage.delete_all
    Log.delete_all
  end
end
