require './test/rails_helper'

module ActionController
  class WithPolicyTest < ActionController::TestCase
    tests :application

    controller :test_policy_scope do
      scope = policy_scope(User.null)
      if scope.empty?
        head :ok
      else
        head :internal_server_error
      end
    end

    controller :test_policy_params do
      params = policy_params(User::Null.new, :show)
      if params.empty?
        head :ok
      else
        head :internal_server_error
      end
    end

    controller :test_policy do
      policy = policy(User::Null.new)
      if policy.show?
        head :internal_server_error
      else
        head :ok
      end
    end

    test '#policy_scope' do
      get :test_policy_scope
      assert_response :ok
    end

    test '#policy_params' do
      get :test_policy_params, params: { user_null: { a: 1 } }
      assert_response :ok
    end

    test '#policy' do
      get :test_policy
      assert_response :ok
    end
  end
end
