require './test/test_helper'

module ActionController
  class WithPolicyTest < ActionDispatch::IntegrationTest
    fixtures :users

    context 'role null' do
      test '#policy_scope' do
        controller_assert :policy_scope do
          policy_scope(User.null).empty?
        end
      end

      test '#policy' do
        controller_assert :policy do
          can = policy(User::Null.new)
          !can.index? && !can.export? && !can.show? && !can.new? && !can.edit? && !can.delete?
        end
      end
    end

    context 'role basic' do
      let(:current_user){ users(:basic) }

      test '#policy_scope' do
        controller_assert :policy_scope do
          policy_scope(User.basic).size == 1
        end
      end

      test '#policy' do
        controller_assert :policy do
          can = policy($test.current_user)
          !can.index? && !can.export? && can.show? && !can.new? && can.edit? && can.delete?
        end
      end
    end

    context 'role admin' do
      let(:current_user){ users(:admin) }

      test '#policy_scope' do
        controller_assert :policy_scope do
          policy_scope(User.admin).size == 1
        end
      end

      test '#policy' do
        controller_assert :policy do
          can = policy($test.current_user)
          can.index? && !can.export? && can.show? && can.new? && can.edit? && can.delete?
        end
      end
    end

    context 'role deployer' do
      let(:current_user){ users(:deployer) }

      test '#policy_scope' do
        controller_assert :policy_scope do
          policy_scope(User.deployer).size == 1
        end
      end

      test '#policy' do
        controller_assert :policy do
          can = policy($test.current_user)
          can.index? && !can.export? && can.show? && can.new? && can.edit? && can.delete?
        end
      end
    end
  end
end
