class RescuePolicy < ApplicationPolicy
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

  def delete?
    user.deployer?
  end
end
