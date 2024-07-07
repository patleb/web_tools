module Test
  class Record < ApplicationRecord
    scope :even, -> { where('"test_records"."id" % 2 = 0') }
    scope :odd,  -> { invert_where(even) }

    has_many :related_records, discardable: true, dependent: :restrict_with_error

    json_attribute :name
    json_attribute secret: :encrypted
    json_attribute info:  [default: ->(record) { "Info for '#{record.name}'" }]
    json_translate title: [default: ->(_record, locale){ locale == :fr ? 'Titre' : 'Title' }]
    json_attribute(
      j_big_integer: :big_integer,
      j_boolean: :boolean,
      j_date: :date,
      j_datetime: :datetime,
      j_decimal: :decimal,
      j_float: :float,
      j_integer: :integer,
      j_json: :json,
      j_string: :string,
      j_text: :text,
      j_time: :time,
      j_interval: :interval
    )
  end
end
