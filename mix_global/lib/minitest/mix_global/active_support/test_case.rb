ActiveSupport::TestCase.class_eval do
  alias_method :run_without_clear_globals, :run
  def run(...)
    result = run_without_clear_globals(...)
    clear_globals unless use_transactional_tests
    result
  end

  def clear_globals
    Global.delete_all
  end
end
