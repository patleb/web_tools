module ActionController::WithPolicy
  extend ActiveSupport::Concern

  included do
    helper_method :policy_scope
    helper_method :policy
  end

  def policy_scope(relation)
    policy = policy(relation.klass)
    policy.scope(relation)
  end

  def policy_params(object, action = action_name)
    policy = policy(object)
    params_method = policy.respond_to?("params_for_#{action}") ? "params_for_#{action}" : 'params'
    params.require(policy.param_key).permit(*policy.public_send(params_method))
  end

  def policy(object)
    (@_policy ||= {})[object] ||= begin
      policy = if object.nil?
        ApplicationPolicy
      else
        klass = object.is_a?(Class) ? object : object.class
        "#{klass.name}Policy".to_const ||
          "#{klass.superclass.name}Policy".to_const ||
          "#{klass.base_class.name}Policy".to_const ||
          ApplicationPolicy
      end
      policy.new(current_user, object)
    end
  end
end
