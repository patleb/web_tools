# frozen_string_literal: true

module ActionController::WithPolicy
  extend ActiveSupport::Concern

  prepended do
    if respond_to? :helper_method
      helper_method :can?, :cannot?
      helper_method :policy_scope
      helper_method :policy
    end
  end

  def can?(action, object)
    policy(object).public_send("#{action}?")
  end

  def cannot?(*)
    !can?(*)
  end

  def policy_scope(relation)
    policy = policy(relation.klass)
    policy.scope(relation)
  end

  def policy(object)
    (@_policy ||= {})[object] ||= begin
      policy = if object
        object = object.is_a?(String) ? object.to_const! : object
        klass = object.is_a?(Class) ? object : object.class
        "#{klass.name}Policy".to_const ||
          "#{klass.superclass.name}Policy".to_const ||
          "#{klass.base_class.name}Policy".to_const ||
          ApplicationPolicy
      else
        ApplicationPolicy
      end
      policy.new(Current.user, object)
    end
  end

  protected

  def set_current
    super
    set_current_user
    set_current_role
  end

  def set_current_user
    return Current.user = default_user unless respond_to? :session
    user_id = session[:user_id]
    user   = User.with_discarded.joins(:session).where(id: user_id).take if user_id.to_i?
    user ||= default_user
    Current.user = user
  end

  def default_user
    User::Null.new
  end

  def set_current_role
    _set_current :role, symbol: true do |role|
      next role if User.roles.has_key? role
      session[:role].presence || Current.user.role
    end
  end

  def default_role
    :null
  end
end
