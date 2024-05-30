### References
# https://mattbrictson.com/minitest-and-rails

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

ActiveRecord.maintain_test_schema = false

# NOTE rails runs test through a rake task in another process which calls require_environment! (so env is loaded twice)
require 'rails/test_help'
require 'shoulda-matchers'
require 'ext_minitest/minitest'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

require 'ext_minitest/active_support/test_case'
