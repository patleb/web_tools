ActiveSupport::TestCase.class_eval do
  delete_tables << 'lib_globals'
end
