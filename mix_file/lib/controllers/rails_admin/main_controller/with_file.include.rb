module RailsAdmin::MainController::WithFile
  extend ActiveSupport::Concern

  included do
    include ActiveStorage::SetCurrent
  end
end
