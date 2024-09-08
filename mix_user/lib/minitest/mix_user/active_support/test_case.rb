ActiveSupport::TestCase.class_eval do
  delete_tables.concat(['lib_user_sessions', 'lib_users'])
end
