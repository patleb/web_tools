module Test
  class MuchRecord < ApplicationRecord
    has_partition size: 5

    belongs_to :relatable, polymorphic: true

    enum! relatable_type: {
      'Test::RelatedRecord' => 1,
    }
  end
end
