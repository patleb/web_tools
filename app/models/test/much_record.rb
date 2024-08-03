module Test
  class MuchRecord < ApplicationRecord
    belongs_to :relatable, polymorphic: true

    enum! relatable_type: {
      'Test::RelatedRecord' => 1,
    }
  end
end
