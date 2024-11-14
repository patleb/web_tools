class UserSessionPolicy < ApplicationPolicy
  def export?
    false
  end

  def show?
    false
  end

  def new?
    false
  end

  def edit?
    false
  end

  def delete?
    false
  end

  class Scope < Scope
    def resolve
      relation.where(user: user)
    end
  end
end
