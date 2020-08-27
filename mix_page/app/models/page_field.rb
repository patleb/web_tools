class PageField < LibRecord
  belongs_to :page
  belongs_to :page_section, optional: true
  belongs_to :fieldable, polymorphic: true

  validates :type, exclusion: { in: ['PageField'] }

  enum type: MixPage.config.available_fields
  enum fieldable_type: MixPage.config.available_fieldables
end
