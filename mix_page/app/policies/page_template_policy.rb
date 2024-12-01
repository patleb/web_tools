class PageTemplatePolicy < ActionPolicy::Base
  def index?
    user.admin?
  end

  def export?
    false
  end

  def show_in_app?
    super && (model? || record.show?)
  end

  def show?
    false
  end

  def new?
    user.admin?
  end

  def edit?
    user.admin?
  end

  def delete?
    edit?
  end

  class Scope < Scope
    def resolve
      user.admin? ? relation.all : super
    end
  end
end
