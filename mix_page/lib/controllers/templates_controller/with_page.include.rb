module TemplatesController::WithPage
  extend ActiveSupport::Concern

  included do
    helper_method :pages_root_path
  end

  def pages_root_path
    @pages_root_path ||= (MixPage.root_path || app_root_path)
  end
end
