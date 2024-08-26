# TODO make sure that flash messages used in mix_admin and mix_page aren't supposed to be flash.now
# action_dispatch/middleware/flash.rb
# https://spartchou.gitbooks.io/ruby-on-rails-basic/content/syntax/flash_vs_flashnow.html
module ActionController::Base::WithFlash
  extend ActiveSupport::Concern

  FLASH_SEPARATOR = '<br>'

  prepended do
    after_action :set_flash_later, if: -> { Current.flash_later? }
  end

  def render(...)
    return super unless session[:flash_later].to_b

    flashes = Flash.dequeue_all
    flashes.each do |record|
      record.messages.each do |type, message|
        (flash.now[type.to_sym] ||= '') << message << FLASH_SEPARATOR
      end
    end
    session.delete(:flash_later) unless flashes.empty?

    super
  end

  private

  def set_flash_later
    session[:flash_later] = true
  end
end
