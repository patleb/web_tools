class PageTemplatePolicy < ApplicationPolicy
  def export?
    false
  end

  def show_in_app?
    record.show?
  end

  def show?
    false
  end
end
