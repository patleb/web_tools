require './test/test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :users

  test '.has_userstamp' do
    Current.user = users(:deployer)
    users(:normal).update! last_name: 'Normie'

    assert_equal users(:deployer), users(:normal).updater
    assert_equal nil, users(:normal).creator

    user = User.create! email: 'example@test.com', password: 'password' * 2
    assert_equal users(:deployer), user.updater
    assert_equal users(:deployer), user.creator
  end
end
