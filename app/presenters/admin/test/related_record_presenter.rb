module Admin::Test
  class RelatedRecordPresenter < Admin::Model
    field :id

    field :name
    field :record
    field :created_at
    field :updated_at
  end
end
