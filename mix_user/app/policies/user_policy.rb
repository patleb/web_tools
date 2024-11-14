class UserPolicy < ApplicationPolicy
  def export?
    false
  end

  def show?
    user.basic?
  end

  def edit?
    if record?
      user.basic? && user.allowed_role?(record)
    else
      logged_in?
    end
  end

  def delete?
    if record?
      user.basic? && user.allowed_role?(record)
    else
      logged_in?
    end
  end

  private

  def logged_in?
    !user.nil?
  end

  class Scope < Scope
    def resolve
      relation.allowed_roles(user)
    end
  end
end
