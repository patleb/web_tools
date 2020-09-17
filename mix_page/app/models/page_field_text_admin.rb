module PageFieldTextAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      field :text, :text, translated: :all

      index do
        exclude_fields :text, translated: true
      end

      show do
        exclude_fields :text
      end

      edit do
        exclude_fields :text
      end
    end
  end
end
