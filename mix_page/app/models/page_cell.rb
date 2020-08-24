class PageCell < LibRecord
  belongs_to :page, counter_cache: true, touch: true
  belongs_to :page_cell, optional: true, counter_cache: true
  has_many   :page_cells, dependent: :destroy
  has_many   :page_contents, dependent: :destroy # TODO STI conversion
end
