module Test
  class RelatedRecord < ApplicationRecord
    has_list

    belongs_to :record, list_parent: true

    json_attribute options: :json
  end
end
