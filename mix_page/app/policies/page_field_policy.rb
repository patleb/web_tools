class PageFieldPolicy < ApplicationPolicy
  def export?
    false
  end

  def new?
    super && !Current.controller.try(:admin?)
  end

  def show?
    false
  end
end
