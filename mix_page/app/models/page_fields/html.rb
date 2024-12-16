module PageFields
  class Html < Text
    has_one :markdown, dependent: :destroy, foreign_key: :page_field_id, class_name: 'PageFieldMarkdown'

    accepts_nested_attributes_for :markdown, update_only: true

    after_create :create_markdown!
  end
end
