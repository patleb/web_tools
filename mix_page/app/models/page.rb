# TODO, -> { select(... except logidze column) }
class Page < LibRecord
  has_userstamp

  has_many :page_cells, dependent: :destroy
  has_many :page_contents, dependent: :destroy

  # TODO Active Storage
  scope :with_contents, -> { includes([
    :page_contents,
    { page_cells: :page_contents },
    { page_cells: { page_cells: :page_contents } }
  ]) }

  validates :type, exclusion: { in: ['Page'] }

  enum type: {
    'Page'         => 0,
    'PageLayout'   => 10,
    'PageTemplate' => 20
  }
end
