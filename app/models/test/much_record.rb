module Test
  class MuchRecord < ApplicationRecord
    has_partition size: 5
  end
end
