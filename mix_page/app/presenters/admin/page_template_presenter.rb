module Admin
  class PageTemplatePresenter < Admin::Model
    record_label_method :title

    field :title

    new do
      field :lock_version
      field :view do
        enum{ klass.available_views }
      end
      field :title,       translated: true
      field :description, translated: true, type: :text
      field :publish,     editable:   true, type: :boolean
      nests :updater, as: :email
      nests :creator, as: :email
      field :updated_at
      field :created_at
      exclude_fields :title
    end

    index do
      searchable false
      include_fields :published_at, :deleted_at, :updated_at, :created_at
    end

    trash do
      exclude_fields :published_at
    end
  end
end
