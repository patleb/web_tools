class PageFieldPolicy < ApplicationPolicy
  def new?
    super && !Current.controller.try(:admin?)
  end

  def export?
    false
  end
end
