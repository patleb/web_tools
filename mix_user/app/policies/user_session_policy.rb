class UserSessionPolicy < ActionPolicy::Base
  def index?
    user.admin?
  end

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
      user.deployer? ? relation.all : relation.where(user: user)
    end
  end
end
