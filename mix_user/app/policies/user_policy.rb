class UserPolicy < ActionPolicy::Base
  def index?
    user.admin?
  end

  def show?
    logged_in? && (model? || allowed_role? || user.has?(record))
  end

  def new?
    user.admin?
  end

  def edit?
    show?
  end

  def delete?
    edit?
  end

  protected

  def allowed_role?
    (user.admin? && user.allowed_role?(record))
  end

  def logged_in?
    !user.nil?
  end

  class Scope < Scope
    def resolve
      relation.allowed_roles(user).or(relation.where(id: user.id))
    end
  end
end
