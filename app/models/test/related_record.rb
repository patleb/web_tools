module Test
  class RelatedRecord < ApplicationRecord
    has_list

    belongs_to :record, list_parent: true
    has_many   :much_records, as: :relatable, dependent: :destroy

    json_attribute options: :json
  end
end
