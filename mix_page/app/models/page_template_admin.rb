module PageTemplateAdmin
  extend ActiveSupport::Concern

  # TODO form button french text breaks on mobile
  # TODO datetime picker doesn't switch to french
  included do
    rails_admin do
      configure :title, translated: :all
      configure :description, :text, translated: :all

      field :view do
        index_value{ primary_key_link(pretty_value) }
      end
      fields :title, :description, translated: :all
      fields :published_at, :updated_at, :updater, :created_at, :creator

      index do
        exclude_fields :title, :description, translated: true
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
