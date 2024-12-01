module Admin
  class PageTemplatePresenter < Admin::Model
    record_label_method :title

    field :lock_version
    field :updated_at
    field :created_at

    new do
      nests :updater, as: :email
      nests :creator, as: :email
      field :view do
        enum{ klass.available_views }
      end
      field :publish, editable: true, type: :boolean
      field :title, translated: true
      field :description, translated: true, type: :text
    end

    index do
      searchable false
      field :title
      include_fields :published_at, :deleted_at, :updated_at, :created_at
    end

    trash do
      exclude_fields :published_at
    end
  end
end
