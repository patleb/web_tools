class LibApiController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  prepend_before_action :set_format
  protect_from_forgery with: :exception

  private

  def set_format
    request.format = :json
  end
end
