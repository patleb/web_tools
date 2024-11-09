module Test
  class RelatedRecord < ApplicationRecord
    has_list

    belongs_to :record, list_parent: true
    has_many   :much_records, as: :relatable, dependent: :destroy

    accepts_nested_attributes_for :record, update_only: true

    json_attribute options: :json
  end
end
