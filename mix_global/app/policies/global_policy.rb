class GlobalPolicy < ActionPolicy::Base
  def index?
    user.deployer?
  end

  def show?
    user.deployer?
  end

  class Scope < Scope
    def resolve
      user.deployer? ? relation.all : super
    end
  end
end
