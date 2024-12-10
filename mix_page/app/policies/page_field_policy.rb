class PageFieldPolicy < ActionPolicy::Base
  def new?
    user.admin? && (model? || record.name.end_with?('s'))
  end

  def edit?
    user.admin?
  end

  def delete?
    edit? && (model? || MixPage.config.permanent_field_names.exclude?(record.name))
  end
end
