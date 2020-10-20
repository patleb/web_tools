module TemplatesController::WithAdmin
  extend ActiveSupport::Concern

  included do
    helper_method :admin_root_path
  end

  def admin_root_path
    RailsAdmin.root_path
  end
end
