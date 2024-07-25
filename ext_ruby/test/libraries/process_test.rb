require './test/spec_helper'

class PathnameTest < Minitest::TestCase
  test '.exist?' do
    assert_equal true, Process.exist?(Process.worker.pid)
    assert_equal false, Process.exist?(-2)
  end
end
