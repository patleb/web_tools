module Admin
  class UserPresenter < Admin::Model
    navigation_i18n_key :system
    record_label_method :email

    field :id
    field :email
    field :role do
      pretty_value{ i18n_value presenter[:as_role] }
      pretty_export{ presenter[:as_role] }
      enum{ Current.user.allowed_roles }
    end

    new do
      field :role do
        readonly{ Current.user.has? presenter }
      end
      include_fields :password, :password_confirmation, type: :password do
        required{ presenter.new_record? }
        allowed{ Current.user.has?(presenter) || presenter.new_record? }
        readonly false
      end
    end

    index do
      include_fields :verified_at, :deleted_at, :updated_at, :created_at
    end

    trash do
      exclude_fields :verified_at
    end

    controller :after_delete do |presenters|
      if presenters.any?{ |presenter| presenter.record == Current.user }
        flash_was = flash.to_hash
        destroy_session! Current.user
        flash.update(flash_was)
        @_back = application_path
      end
    end
  end
end
