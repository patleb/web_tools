module Admin
  class UserPresenter < Admin::Model
    navigation_i18n_key :system
    record_label_method :email

    field :id
    field :email
    field :role do
      enum{ Current.user.allowed_roles }
    end

    new do
      include_fields :password, :password_confirmation, weight: 1, type: :password do
        required{ presenter.new_record? }
        allowed{ Current.user.has?(presenter) || presenter.new_record? }
        readonly false
      end
      field :role do
        readonly{ Current.user.has? presenter }
      end
    end

    index do
      include_fields :verified_at, :deleted_at, :updated_at, :created_at, weight: 1
    end

    trash do
      exclude_fields :verified_at
    end
  end
end
