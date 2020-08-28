class PageField < LibRecord
  has_list

  belongs_to :page
  belongs_to :fieldable, optional: true, polymorphic: true

  validates :type, exclusion: { in: ['PageField'] }

  enum type: MixPage.config.available_fields
  enum key: MixPage.config.available_field_keys
  enum fieldable_type: MixPage.config.available_fieldables
end
