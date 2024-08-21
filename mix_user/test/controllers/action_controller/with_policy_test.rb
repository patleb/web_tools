require './test/test_helper'

module ActionController
  class WithPolicyTest < ActionDispatch::IntegrationTest
    test '#policy_scope' do
      controller_assert :policy_scope do
        policy_scope(User.null).empty?
      end
    end

    test '#policy_params' do
      controller_assert :policy_params, params: { user_null: { a: 1 } } do
        policy_params(User::Null.new, :show).empty?
      end
    end

    test '#policy' do
      controller_refute :policy do
        policy(User::Null.new).show?
      end
    end
  end
end
