module Current::WithUser
  extend ActiveSupport::Concern

  included do
    attribute :user
    attribute :user_logged_in
  end

  def user_logged_in?
    user_logged_in.to_b
  end
end
