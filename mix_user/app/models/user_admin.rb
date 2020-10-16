module UserAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label_i18n_key :system
      navigation_weight 999

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
          readonly{ Current.user.has? object }
        end
      end

      index do
        field :email do
          index_value{ primary_key_link }
        end
        # TODO should be able to filter by enum
        field :role do
          searchable false
          queryable false
        end
        fields :confirmed_at, :updated_at, :created_at
      end
    end
  end
end
