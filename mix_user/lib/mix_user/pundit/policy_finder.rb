module Pundit::PolicyFinder::WithNilableCache
  def scope
    "#{policy}::Scope".to_const
  end

  def policy
    find_policy(object) || find_parent_policy(object) || ::ApplicationPolicy
  end

  private

  def find_policy(object)
    object && "#{find(object)}#{Pundit::SUFFIX}".to_const
  end

  def find_parent_policy(object)
    object && sti_child?(object) && "#{find_parent(object)}#{Pundit::SUFFIX}".to_const
  end

  def find(subject)
    subject.model_name
  end

  def sti_child?(subject)
    if subject.is_a? Class
      subject.sti? && !subject.base_class?
    else
      sti_child? subject.class
    end
  end

  def find_parent(subject)
    if subject.is_a? Class
      subject.base_class.model_name
    else
      find_parent(subject.class)
    end
  end
end

Pundit::PolicyFinder.prepend Pundit::PolicyFinder::WithNilableCache
