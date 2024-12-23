module Current::WithFlash
  extend ActiveSupport::Concern

  included do
    attribute :flash

    def flash?
      flash && flash.messages.present?
    end
  end
end
