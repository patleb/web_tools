module Current::WithUser
  extend ActiveSupport::Concern

  included do
    attribute :user
    attribute :user_logged_in
    attribute :user_role

    alias_method :user_logged_in?, :user_logged_in

    def user_role?
      user_role == 'true'
    end
  end
end
