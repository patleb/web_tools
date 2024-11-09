module Admin::Test
  class RelatedRecordPresenter < Admin::Model
    record_label_method :name

    field :id

    field :name do
      full_query_column true
    end
    nests :record
    field :created_at
    field :updated_at
  end
end
