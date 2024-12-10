class UserSessionPolicy < ActionPolicy::Base
  def index?
    user.admin?
  end

  class Scope < Scope
    def resolve
      user.deployer? ? relation.all : relation.where(user: user)
    end
  end
end
