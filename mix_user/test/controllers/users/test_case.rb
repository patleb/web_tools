class Users::TestCase < ActionDispatch::IntegrationTest
  test_queue_adapter!

  private

  def assert_session_created
    assert_equal session[:user_id], Current.user.id
    assert_equal session[:session_id], Current.user.session_id
  end

  def assert_session_destroyed
    refute user.reload.session
    assert_equal nil, session[:user_id]
    assert_equal User::Null.new, Current.user
  end

  def assert_alert
    assert flash[:alert].present?
  end

  def assert_notice
    assert flash[:notice].present?
  end

  def assert_authenticated
    assert Current.user.is_a?(User)
  end

  def assert_unauthenticated
    assert Current.user.is_a?(User::Null)
  end
end
