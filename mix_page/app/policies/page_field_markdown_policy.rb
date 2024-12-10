class PageFieldMarkdownPolicy < ActionPolicy::Base
  def edit?
    user.admin?
  end
end
