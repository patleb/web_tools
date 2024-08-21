module Admin
  class UserPresenter < Admin::Model
    navigation_i18n_key :system
    navigation_weight 999
    record_label_method :email

    edit do
      field :email do
        required true
      end
      field :role do
        readonly{ Current.user.has? object }
      end
      include_fields :password, :password_confirmation do
        required{ object.new_record? }
        allowed{ Current.user.has?(object) || object.new_record? }
      end
    end

    index do
      field :email do
        pretty_value{ section.name == :index ? primary_key_link : pretty_value }
      end
      field :role
      include_fields :confirmed_at, :updated_at, :created_at
    end
  end
end
