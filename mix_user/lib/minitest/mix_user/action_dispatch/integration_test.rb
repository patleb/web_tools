ActionDispatch::IntegrationTest.class_eval do
  include Devise::Test::IntegrationHelpers if defined? Devise
end
