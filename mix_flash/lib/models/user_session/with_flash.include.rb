module UserSession::WithFlash
  extend ActiveSupport::Concern

  included do
    json_attribute flash_later: :boolean
  end

  def flash_later!
    update! flash_later: true
  end

  def flash_now!
    update! flash_later: false
  end
end
