module Admin::Test
  class RecordPresenter < Admin::Model
    field :id

    nests :nested_record do
      field :name do
        full_query_name true
      end
    end
    nests :related_records
    nests :related_record
    field :boolean
    field :date
    field :datetime, type: :datetime
    field :decimal
    field :deleted_at
    field :integer
    field :json
    field :lock_version
    field :password
    field :string
    field :text
    field :time
    field :uuid
    field :j_code, type: :code do
      readonly false
    end
  end
end
