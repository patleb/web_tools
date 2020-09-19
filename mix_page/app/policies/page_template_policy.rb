class PageTemplatePolicy < ApplicationPolicy
  def export?
    false
  end

  def show_in_app?
    record.kept? && record.published? || user.admin?
  end

  def show?
    false
  end
end
