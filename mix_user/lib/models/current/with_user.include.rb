module Current::WithUser
  extend ActiveSupport::Concern

  included do
    attribute :user
    attribute :role

    def logged_in?
      !user.nil?
    end

    User.roles.each_key do |role_name|
      define_method "as_#{role_name}?" do
        role == role_name
      end
    end
  end

  def user_session
    user.session
  end
end
