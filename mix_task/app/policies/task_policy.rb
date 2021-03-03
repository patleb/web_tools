class TaskPolicy < ApplicationPolicy
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
    user.deployer?
  end

  def delete?
    false
  end
end
