class PageField < LibRecord
  has_userstamp
  has_list

  belongs_to :page
  belongs_to :fieldable, optional: true, polymorphic: true

  enum type: MixPage.config.available_fields
  enum key: MixPage.config.available_field_keys
  enum fieldable_type: MixPage.config.available_fieldables
end
