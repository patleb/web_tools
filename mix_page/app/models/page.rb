# TODO, -> { select(... except logidze column) }
class Page < LibRecord
  has_userstamp

  has_many :page_fields, -> { order(:position) }, dependent: :destroy

  scope :with_content, -> { includes(page_fields: :fieldable) }

  enum type: {
    'PageLayout'   => 10,
    'PageTemplate' => 20
  }

  attr_readonly *%i(
    uuid
    type
    view
    page_templates_count
    page_fields_count
  )

  after_discard -> { discard_all! :page_fields }
  before_undiscard -> { undiscard_all! :page_fields }
end
