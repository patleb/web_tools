class GlobalPolicy < ApplicationPolicy
  def index?
    user.deployer?
  end

  def export?
    false
  end

  def show?
    user.deployer?
  end

  def new?
    false
  end

  def edit?
    false
  end

  def destroy?
    user.deployer?
  end
end
