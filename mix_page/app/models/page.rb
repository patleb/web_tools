# TODO, -> { select(... except logidze column) }
class Page < LibRecord
  has_userstamp
  has_list

  has_many :page_sections, dependent: :destroy
  has_many :page_fields, dependent: :destroy

  # TODO Active Storage
  scope :with_contents, -> { includes([
    :page_fields,
    { page_sections: :page_fields },
    { page_sections: { page_sections: :page_fields } }
  ]) }

  validates :type, exclusion: { in: ['Page'] }

  enum type: {
    'Page'         => 0,
    'PageLayout'   => 10,
    'PageTemplate' => 20
  }
end
