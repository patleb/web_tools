require './test/test_helper'

class MonkeyPatchTest < ActionMailer::TestCase
  test '.verify_all!' do
    assert_nothing_raised do
      MonkeyPatch.verify_all!
    end
  end
end
