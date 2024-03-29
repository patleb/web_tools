class PageFieldPolicy < ApplicationPolicy
  def index?
    super && !record.base_class?
  end

  def export?
    false
  end

  def new?
    super && Current.controller_was.try(:pages?)
  end

  def show?
    false
  end
end
