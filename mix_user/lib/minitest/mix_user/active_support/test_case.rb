ActionController::Base.class_eval do
  module self::WithTestUser
    def set_current_user
      Current.user = $test.try(:current_user)
      super unless Current.user
    end
  end
  prepend self::WithTestUser
end

ActiveSupport::TestCase.class_eval do
  delete_tables.concat(['lib_user_sessions', 'lib_users'])

  def create_session!
    Current.session_id = current_user.sessions.create!(
      session_id: SecureRandom.hex(16),
      ip_address: '127.0.0.1',
      user_agent: []
    ).sid
  end
end
