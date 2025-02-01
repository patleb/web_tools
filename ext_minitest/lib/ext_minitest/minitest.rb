require 'minitest/autorun'

require 'ext_ruby'
require 'active_support/testing/time_helpers'
ENV['MT_NO_EXPECTATIONS'] = 'true'
require 'ext_minitest/minitest/assertions'
require 'ext_minitest/minitest/test'
require 'ext_minitest/minitest/spec/dsl'
require 'ext_minitest/minitest/test_case'
require 'ext_minitest/minitest/unexpected_error' if ENV['RM_INFO'].present?
