# TODO, -> { select(... except logidze column) }
class Page < LibRecord
  has_userstamp
  has_list

  has_many :page_fields, -> { Current.user.admin? ? with_discarded : all }, dependent: :destroy

  scope :with_contents, -> { includes(:page_fields) } # TODO Active Storage

  validates :type, exclusion: { in: ['Page'] }

  enum type: {
    'Page'         => 0,
    'PageLayout'   => 10,
    'PageTemplate' => 20
  }

  attr_readonly *%i(
    uuid
    page_templates_count
    page_fields_count
  )
end
