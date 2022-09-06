module ActionController::WithPolicy
  extend ActiveSupport::Concern

  included do
    helper :policy_scope
    helper :policy
  end

  def policy_scope(objects)
    policy = policy(objects.last)
    policy.scope(objects)
  end

  def policy_params(object, action = action_name)
    policy = policy(object)
    params_method = policy.respond_to?("params_for_#{action}") ? "params_for_#{action}" : 'params'
    params.require(policy.param_key).permit(*policy.public_send(params_method))
  end

  def policy(object)
    (@_policy ||= {})[object] ||= begin
      policy = ActionPolicy::Finder.new(object).policy
      policy.new(current_user, object)
    end
  end
end
