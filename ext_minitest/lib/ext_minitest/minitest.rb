require 'minitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'

require 'ext_ruby'
ENV['MT_NO_EXPECTATIONS'] = true
require 'ext_minitest/minitest/assertions'
require 'ext_minitest/minitest/test'
require 'ext_minitest/minitest/spec/dsl'
require 'ext_minitest/minitest/test_case'
require 'ext_minitest/minitest/unexpected_error'
