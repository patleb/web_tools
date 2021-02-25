module Current::WithUser
  extend ActiveSupport::Concern

  included do
    attribute :user
    attribute :as_user

    alias_method :as_user?, :as_user

    def logged_in?
      user && user.id > ActiveType::NullObject::ID
    end
  end
end
