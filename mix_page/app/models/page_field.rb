class PageField < LibRecord
  has_userstamp
  has_list

  belongs_to :page
  belongs_to :page_layout, foreign_key: :page_id
  belongs_to :page_template, foreign_key: :page_id
  belongs_to :fieldable, optional: true, polymorphic: true

  enum type: MixPage.config.available_fields
  enum key: MixPage.config.available_field_keys
  enum fieldable_type: MixPage.config.available_fieldables

  attr_readonly *%i(
    type
    page_id
    key
  )
end
