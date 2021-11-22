class UserPolicy < ApplicationPolicy
  def export?
    false
  end

  def show?
    false
  end

  def edit?
    if record.is_a? User
      super && user.visible_role?(record)
    else
      super
    end
  end

  def delete?
    if record.is_a? User
      super && user.visible_role?(record)
    else
      super
    end
  end

  class Scope < Scope
    def resolve
      scope.visible_roles(user)
    end
  end
end
