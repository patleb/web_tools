class ApplicationPolicy < ActionPolicy::Base
  def index?
    user.admin?
  end

  def export?
    user.admin?
  end

  def show?
    user.admin?
  end

  def new?
    user.admin?
  end

  def edit?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
