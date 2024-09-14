ActionController::Base.class_eval do
  module self::WithTestUser
    def set_current_user
      Current.user = $test.try(:user)
      super unless Current.user
    end
  end
  prepend self::WithTestUser
end

ActiveSupport::TestCase.class_eval do
  delete_tables.concat(['lib_user_sessions', 'lib_users'])
end
