ActiveSupport::TestCase.class_eval do
  delete_tables << 'lib_tasks'
end
