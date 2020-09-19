module PageTemplateAdmin
  extend ActiveSupport::Concern

  # TODO form button french text breaks on mobile
  # TODO datetime picker doesn't switch to french
  included do
    rails_admin do
      configure :title, translated: :all
      configure :description, :text, translated: :all

      fields :view
      fields :title, :description, translated: :all
      fields :published_at, :updated_at, :created_at

      index do
        sort_by :updated_at
        exclude_fields :title, :description, translated: true
      end

      show do
        include_fields :creator, :updater, :uuid
        exclude_fields :title, :description
      end

      edit do
        field :publish, :boolean do
          readonly false
        end
        exclude_fields :title, :description, :published_at
      end
    end
  end
end
