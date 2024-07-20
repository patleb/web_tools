### Documentation
# http://mattsears.com/articles/2011/12/10/minitest-quick-reference/
# http://docs.seattlerb.org/minitest/Minitest/Expectations.html

require 'maxitest/autorun'
require 'mocha/minitest'
require 'webmock/minitest'

require 'ext_ruby'
ENV['MT_NO_EXPECTATIONS'] = true
require 'ext_minitest/minitest/assertions'
require 'ext_minitest/minitest/test'
require 'ext_minitest/minitest/spec/dsl'
require 'ext_minitest/minitest/test_case'
require 'ext_minitest/minitest/unexpected_error'
