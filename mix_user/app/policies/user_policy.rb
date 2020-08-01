class UserPolicy < ApplicationPolicy
  def export?
    false
  end

  def show?
    false
  end

  class Scope < Scope
    def resolve
      scope.visible_roles(user)
    end
  end
end
