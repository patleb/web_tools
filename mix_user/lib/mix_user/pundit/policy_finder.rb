module Pundit::PolicyFinder::WithNilableCache
  def scope
    "#{policy}::Scope".to_const
  end

  def policy
    object && "#{find(object)}#{Pundit::SUFFIX}".to_const || ::ApplicationPolicy
  end

  private

  def find(subject)
    subject.model_name
  end
end

Pundit::PolicyFinder.prepend Pundit::PolicyFinder::WithNilableCache
