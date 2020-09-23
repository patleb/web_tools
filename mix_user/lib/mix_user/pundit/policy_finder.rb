module Pundit::PolicyFinder::WithNilableCache
  def scope
    "#{policy}::Scope".to_const
  end

  def policy
    find_policy(object) || find_superclass_policy(object) || find_base_class_policy(object) || ::ApplicationPolicy
  end

  private

  def find_policy(object)
    object && "#{find_class(object).name}#{Pundit::SUFFIX}".to_const
  end

  def find_class(subject)
    subject.is_a?(Class) ? subject : subject.class
  end

  def find_superclass_policy(object)
    object && "#{find_superclass(object).name}#{Pundit::SUFFIX}".to_const
  end

  def find_base_class_policy(object)
    object && sti_child?(object) && "#{find_base_class(object).name}#{Pundit::SUFFIX}".to_const
  end

  def sti_child?(subject)
    if subject.is_a? Class
      subject.sti? && !subject.superclass.base_class? && !subject.base_class?
    else
      sti_child? subject.class
    end
  end

  def find_superclass(subject)
    subject.is_a?(Class) ? subject.superclass : find_superclass(subject.class)
  end

  def find_base_class(subject)
    subject.is_a?(Class) ? subject.base_class : find_base_class(subject.class)
  end
end

Pundit::PolicyFinder.prepend Pundit::PolicyFinder::WithNilableCache
