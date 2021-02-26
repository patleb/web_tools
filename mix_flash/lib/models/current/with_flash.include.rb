module Current::WithFlash
  extend ActiveSupport::Concern

  included do
    attribute :flash
    attribute :flash_later

    alias_method :flash_later?, :flash_later

    def flash?
      flash && flash.messages.present?
    end
  end
end
