ActiveSupport::TestCase.class_eval do
  class_attribute :clear_logs, instance_accessor: false, instance_predicate: false, default: true

  alias_method :run_without_clear_logs, :run
  def run(...)
    result = run_without_clear_logs(...)
    clear_logs if self.class.clear_logs
    result
  end

  def clear_logs
    LogLine.delete_all
    LogMessage.delete_all
    Log.delete_all
    Server.delete_all
  end
end
