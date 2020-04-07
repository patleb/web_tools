class UserPolicy < ApplicationPolicy
  def export?
    false
  end

  def show?
    false
  end
end
