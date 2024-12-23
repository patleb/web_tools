module ActionController::Base::WithFlash
  extend ActiveSupport::Concern

  prepended do
    after_action :save_flash, if: -> { Current.flash? }
  end

  def render(...)
    if request.format.html? && Current.user_session&.flash_later?
      Current.user_session.flash_now!
      Flash.dequeue_in(flash.now)
    end
    super
  end

  private

  def save_flash
    Current.flash.save!
  end
end
