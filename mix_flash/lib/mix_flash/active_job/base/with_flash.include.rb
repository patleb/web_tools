module ActiveJob::Base::WithFlash
  extend ActiveSupport::Concern

  included do
    after_perform :save_flash, if: -> { Current.flash? }
  end

  private

  def save_flash
    Current.flash.save!
  end
end
