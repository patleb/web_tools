module Current::WithUser
  extend ActiveSupport::Concern

  included do
    attribute :user
    attribute :user_logged_in
    alias_method :user_logged_in?, :user_logged_in
  end
end
