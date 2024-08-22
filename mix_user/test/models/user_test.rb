require './test/test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :users

  let(:deployer){ users(:deployer) }
  let(:admin){ users(:admin) }
  let(:basic){ users(:basic) }
  let(:null){ User::Null.new }

  test '.has_userstamp' do
    Current.user = deployer
    basic.update! last_name: 'Normie'

    assert_equal deployer, basic.updater
    assert_equal nil, basic.creator

    user = User.create! email: 'example@test.com', password: 'password' * 2
    assert_equal deployer, user.updater
    assert_equal deployer, user.creator
  end

  test '#role' do
    assert User.admin_created?
    Current.user = admin
    assert_equal [:basic, :admin], User.enum_roles.keys
    Current.role = :basic
    assert_equal [:basic], User.enum_roles.keys

    refute admin.role_deployer?
    assert admin.role_admin?
    assert admin.role_basic?
    assert admin.role_null?

    refute admin.deployer?
    refute admin.admin?
    assert admin.basic?
    assert admin.null?

    refute admin.visible_role?(deployer)
    refute admin.visible_role?(admin)
    assert admin.visible_role?(basic)

    refute admin.has?(deployer)
    assert admin.has?(admin)
    refute admin.has?(basic)

    assert_equal :basic, deployer.as_role
    assert_equal :basic, admin.as_role
    assert_equal :basic, basic.as_role
    assert_equal :null, null.as_role

    user = User.new(email: 'Example@Test.com', password: 'password' * 2, role: 'null')
    refute user.valid?
    assert_equal 'example@test.com', user.email
    assert_equal :null, user.role
    user = User.new(email: 'example@test.com', password: 'password' * 2, role: 'deployer')
    refute user.valid?
  end
end
