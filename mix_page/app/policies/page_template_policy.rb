class PageTemplatePolicy < ApplicationPolicy
  def export?
    false
  end

  def show_in_app?
    record.kept? && record.published? || user.admin?
  end
end
