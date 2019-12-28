### References
# https://mattbrictson.com/minitest-and-rails

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

ActiveRecord::Base.maintain_test_schema = false

# TODO rails runs test through a rake task in another process which calls require_environment! (so env is loaded twice)
require 'rails/test_help'
require 'shoulda-matchers'
require 'minitest-spec-rails/init/mini_shoulda'
require 'vcr'
require 'ext_minitest/minitest'
require 'ext_minitest/vcr'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { serialize_with: :json }
end

require 'ext_minitest/active_support/test_case'
