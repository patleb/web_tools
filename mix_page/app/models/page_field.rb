class PageField < LibRecord
  belongs_to :page, counter_cache: true, touch: true
  belongs_to :page_section, optional: true, counter_cache: true

  validates :type, exclusion: { in: ['PageField'] }

  enum type: MixPage.config.available_fields
end
