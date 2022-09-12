class UserPolicy < ApplicationPolicy
  def export?
    false
  end

  def show?
    false
  end

  def edit?
    super && user.visible_role?(record)
  end

  def delete?
    super && user.visible_role?(record)
  end

  class Scope < Scope
    def resolve
      scope.visible_roles(user)
    end
  end
end
