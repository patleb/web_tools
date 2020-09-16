module PageTemplateAdmin
  extend ActiveSupport::Concern

  # TODO form button french text breaks on mobile
  # TODO datetime picker doesn't switch to french
  included do
    rails_admin do
      configure :title
      configure :description
      configure :title, translated: true do
        readonly false
      end
      configure :description, :text, translated: true do
        readonly false
      end

      fields :title, :description, translated: true
      fields :view, :title, :description, :created_at, :updated_at, :published_at

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
