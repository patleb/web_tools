module LibController::WithPage
  extend ActiveSupport::Concern

  included do
    helper_method :pages_root_path
  end

  def pages_root_path
    @pages_root_path ||= if MixPage.config.root_path.present?
      MixPage.config.root_path
    elsif (page = PageTemplate.find_root_page)&.show?
      page.to_url
    else
      application_path
    end
  end
end
