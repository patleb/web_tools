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
          required true
        end
      end

      index do
        sort_by :updated_at
        field :email do
          index_value{ primary_key_link }
        end
        fields :updated_at, :created_at
      end
    end
  end
end
