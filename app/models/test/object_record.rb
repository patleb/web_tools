module Test
  class ObjectRecord < VirtualRecord::Base
    scope :even, -> { select{ |record| record.id.even? } }

    ar_attribute :name
    attribute    :date, :date,     default: ->(record) { record.id.days.from_now.to_date }
    attribute    :odd,  :boolean,  default: ->(record) { record.id.odd? }
    enum type: [:simple, :complex].map.with_index.to_h, default: :simple

    def self.list
      11.times.map{ |i| { id: i, name: "Name #{i}" } } << { id: -1, name: '' }
    end
  end
end
