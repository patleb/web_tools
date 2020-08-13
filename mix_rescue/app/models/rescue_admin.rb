module RescueAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label I18n.t('admin.navigation.system')
      weight 999

      configure :message do
        simple_formatted true
      end

      index do
        sort_by :updated_at
      end

      exclude_fields :id
    end
  end
end
