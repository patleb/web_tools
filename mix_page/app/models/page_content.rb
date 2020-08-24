class PageContent < LibRecord
  belongs_to :page, counter_cache: true, touch: true
  belongs_to :page_cell, optional: true, counter_cache: true

  validates :type, exclusion: { in: ['PageContent'] }

  enum type: MixPage.config.available_contents
end
