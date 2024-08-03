module LogLines::EmailAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_i18n_key :system
      navigation_weight 999

      index do
        sort_by :id
      end

      exclude_fields :id
    end
  end
end
