ActiveSupport::TestCase.class_eval do
  alias_method :run_without_clear_users, :run
  def run(...)
    result = run_without_clear_users(...)
    clear_users unless use_transactional_tests
    result
  end

  def clear_users
    UserSession.delete_all
    User.unscoped.delete_all
  end
end
