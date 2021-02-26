module JobsController::WithFlash
  extend ActiveSupport::Concern

  included do
    after_action :save_flash, if: -> { Current.flash? }
  end

  private

  def save_flash
    Current.flash.save!
  end
end
