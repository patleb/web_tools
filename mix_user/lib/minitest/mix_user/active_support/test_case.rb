ActiveSupport::TestCase.class_eval do
  delete_tables.concat(%w(lib_user_sessions lib_users))
end
