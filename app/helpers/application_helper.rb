module ApplicationHelper
  def error_link
    li_ do
      a_ '.error_link', [icon('exclamation-circle'), t('link.error')], href: '/error'
    end
  end
end
