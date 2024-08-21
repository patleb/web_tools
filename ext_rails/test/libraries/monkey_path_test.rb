require './test/test_helper'

class MonkeyPatchTest < ActiveSupport::TestCase
  let(:run_timeout){ 2 }

  test '.verify_all!' do
    Rails.application.eager_load!
    ActionView.eager_load!
    assert_nothing_raised do
      MonkeyPatch.verify_all!
    end
  end
end
