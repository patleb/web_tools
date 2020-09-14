module GlobalAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      navigation_weight 999

      configure :id do
        readonly true
      end

      configure :data do
        visible true
        separated true
      end

      configure :data_type do
        readonly true
      end

      show do
        exclude_fields :data_type, :data
      end

      index do
        scopes [:all, :permanent, :expirable, :ongoing, :expired]
        sort_by :updated_at
        include_fields :id, :expires, :expires_at, :version, :data_type, :data, :updated_at
      end

      edit do
        field :id
        field :expires
        field :expires_at
        field :version
        Global.data_types.each_key do |type|
          field type do
            visible do
              object.data_type == type
            end
          end
        end
      end
    end
  end
end
