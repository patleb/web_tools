module ActionController::Base::WithFlash
  extend ActiveSupport::Concern

  prepended do
    after_action :save_flash, if: -> { Current.flash? }
    after_action :set_flash_later, if: -> { Current.flash_later? }
  end

  def render(...)
    if session.delete(:flash_later).to_b
      Flash.dequeue_in(flash.now)
    end
    super
  end

  private

  def save_flash
    Current.flash.save!
  end

  def set_flash_later
    session[:flash_later] = true
  end
end
