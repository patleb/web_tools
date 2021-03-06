module PageTemplateAdmin
  extend ActiveSupport::Concern

  # TODO form button french text breaks on mobile
  # TODO datetime picker doesn't switch to french
  included do
    rails_admin do
      field :lock_version
      configure :title, translated: :all do
        searchable false
        index_value{ primary_key_link(pretty_value) }
      end
      configure :description, :text, translated: :all do
        searchable false
      end
      field :view do
        searchable false
      end
      fields :title, :description, translated: :all
      fields :published_at, :updated_at, :created_at do
        searchable false
        queryable false
      end

      index do
        exclude_fields :view
        exclude_fields :title, translated: true
        exclude_fields :description, translated: :all
      end

      edit do
        configure :view do
          enum_method :available_views
        end
        field :publish, :boolean do
          readonly false
        end
        fields :updater, :creator
        exclude_fields :title, :description, :published_at
      end
    end
  end
end
