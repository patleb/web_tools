module RescueAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_label_i18n_key :system
      navigation_weight 999

      configure :message, :code do
        pretty_value{ value.join }
      end

      index do
        sort_by :updated_at
      end

      exclude_fields :id
    end
  end
end
