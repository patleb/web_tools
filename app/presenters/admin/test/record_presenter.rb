module Admin::Test
  class RecordPresenter < Admin::Model
    field :id

    field :boolean
    field :date
    field :datetime, type: :datetime
    field :decimal
    field :deleted_at
    field :integer
    field :json
    field :lock_version
    field :password
    field :string do
      help "Any text"
    end
    field :text
    field :time
    field :uuid
  end
end
