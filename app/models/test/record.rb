module Test
  class Record < ApplicationRecord
    include Searchable

    scope :even,  -> { where('"test_records"."id" % 2 = 0') }
    scope :odd,   -> { invert_where(even) }
    scope :today, -> { where(date: Time.current.beginning_of_day..Time.current.end_of_day) }

    has_many :related_records, discardable: :all, dependent: :restrict_with_error
    has_one  :related_record, -> { all_discardable.where(position: 5.0) }, discardable: :all, dependent: :restrict_with_error
    has_one  :nested_record, -> { all_discardable.where(position: 5.0) }, discardable: :all, class_name: 'Test::RelatedRecord'

    accepts_nested_attributes_for :nested_record, update_only: true

    json_attribute :name
    json_attribute secret: :encrypted
    json_attribute info:  [default: ->(record) { "Info for '#{record.name}'" }]
    json_translate title: [default: proc{ I18n.locale == :fr ? 'Titre' : 'Title' }]
    json_attribute(
      j_big_integer: :big_integer,
      j_boolean: :boolean,
      j_code: :text,
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

    enum _default: :zero, integer: {
      zero:  0,
      one:   1,
      two:   2,
      three: 3,
      four:  4,
      five:  5,
    }

    validates :string, presence: true

    def raw_search_words
      [name, info, title, string, text, j_string, j_text].concat(related_records.flat_map(&:name))
    end
  end
end
