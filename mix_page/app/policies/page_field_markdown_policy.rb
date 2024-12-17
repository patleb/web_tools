class PageFieldMarkdownPolicy < ActionPolicy::Base
  def edit?
    user.admin?
  end

  def upload?
    edit?
  end
end
