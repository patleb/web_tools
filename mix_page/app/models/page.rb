# TODO, -> { select(... except logidze column) }
class Page < LibRecord
  has_userstamp

  has_many :page_fields, -> { order(:position) }, dependent: :destroy

  scope :with_content, -> { includes(:page_fields) } # TODO Active Storage

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

  after_discard :discard_page_fields
  before_undiscard :undiscard_page_fields

  private

  def discard_page_fields
    PageField.without_default_scope { page_fields.discard_all! }
  end

  def undiscard_page_fields
    PageField.without_default_scope do
      page_fields.where(PageField.column(:updated_at) >= updated_at - 1.second).undiscard_all!
    end
  end
end
