# TODO, -> { select(... except logidze column) }
class Page < LibRecord
  has_userstamp
  has_list

  has_many :page_fields, -> { order(:position) }, dependent: :destroy

  scope :with_content, -> { includes(:page_fields) } # TODO Active Storage

  enum type: {
    'PageLayout'   => 10,
    'PageTemplate' => 20
  }

  attr_readonly *%i(
    type
    uuid
    view
    page_templates_count
    page_fields_count
  )
end
