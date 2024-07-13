ActiveSupport::TestCase.class_eval do
  alias_method :run_without_clear_logs, :run
  def run(...)
    result = run_without_clear_logs(...)
    clear_logs unless use_transactional_tests
    result
  end

  def clear_logs
    LogLine.delete_all
    LogMessage.delete_all
    Log.delete_all
    Server.delete_all
  end
end
