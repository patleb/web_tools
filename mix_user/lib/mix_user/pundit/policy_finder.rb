module Pundit::PolicyFinder::WithNilableCache
  def scope
    ActiveSupport::Dependencies.safe_constantize("#{policy}::Scope")
  end

  def policy
    object && ActiveSupport::Dependencies.safe_constantize("#{find(object)}#{Pundit::SUFFIX}") || ::ApplicationPolicy
  end

  private

  def find(subject)
    subject.model_name
  end
end

Pundit::PolicyFinder.prepend Pundit::PolicyFinder::WithNilableCache
