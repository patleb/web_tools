class PageField < LibRecord
  belongs_to :page
  belongs_to :page_section, optional: true

  validates :type, exclusion: { in: ['PageField'] }

  enum type: MixPage.config.available_fields
end
