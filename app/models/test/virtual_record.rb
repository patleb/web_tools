module Test
  class VirtualRecord < VirtualRecord::Base
    scope :even, -> { select{ |record| record.id.even? } }

    ar_attribute :name
    attribute    :date, :date,     default: ->(record) { record.id.days.from_now.to_date }
    attribute    :odd,  :boolean,  default: ->(record) { record.id.odd? }

    def self.list
      11.times.map{ |i| { id: i, name: "Name #{i}" } } << { id: -1, name: '' }
    end

    def values
      attributes.symbolize_keys
    end
  end
end
