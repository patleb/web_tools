module UserAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      weight 999

      object_label_method do
        :email
      end

      edit do
        field :email do
          required true
        end
        field :password do
          required{ object.new_record? }
          visible{ Current.user.has?(object) || object.new_record? }
        end
        field :role do
          enum{ Current.user.visible_roles_i18n }
          readonly{ Current.user.has? object }
        end
      end

      index do
        sort_by :updated_at
        field :email do
          index_value{ primary_key_link }
        end
        fields :updated_at, :created_at, :confirmed_at, :role
      end
    end
  end
end
