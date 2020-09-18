class PageField < LibRecord
  has_userstamp
  has_list

  belongs_to :page, -> { with_discarded }
  belongs_to :page_layout, -> { with_discarded }, foreign_key: :page_id
  belongs_to :page_template, -> { with_discarded }, foreign_key: :page_id
  belongs_to :fieldable, optional: true, polymorphic: true

  enum type: MixPage.config.available_field_types
  enum name: MixPage.config.available_field_names
  enum fieldable_type: MixPage.config.available_fieldables

  attr_readonly *%i(
    type
    name
    page_id
  )
end
