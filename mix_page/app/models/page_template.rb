class PageTemplate < Page
  belongs_to :page_layout

  validates :view, presence: true
  validates :view, uniqueness: { scope: :page_layout_id }, if: -> { view_changed? && unique? }
  validate  :slug_exclusion

  enum view: MixPage.config.available_templates

  json_translate(
    title: [:string, default: ->(record) { record.default_title }],
    description: [:string, default: ->(record) { record.title }]
  )

  attr_writer :publish

  before_validation :set_published_at, if: :publish_changed?

  def self.state_of(uuid)
    layouts = alias_table(:layouts)
    with_discarded
      .where(uuid: uuid).joins(join(layouts).on(column(:page_layout_id).eq(layouts[:id])).join_sources)
      .select(:id, :uuid, :view, :json_data, :deleted_at, :published_at, greatest(:updated_at, layouts[:updated_at]))
      .first
  end

  def layout
    @layout ||= PageLayout.with_content.readonly.find(page_layout_id)
  end

  def publish
    @publish.nil? ? published? : @publish.to_b
  end

  def publish_changed?
    !@publish.nil? && published? != publish
  end

  def published?
    published_at&.past?.to_b
  end

  def unique?
    view && !view.end_with?(MixPage::MULTI_VIEW)
  end

  def to_url(*args)
   host = Rails.application.routes.default_url_options[:host]
   port = Rails.application.routes.default_url_options[:port]
   protocol = "http#{'s' if Rails.application.config.force_ssl}://"
   [protocol, host, (':' if port), port, "/#{slug(*args)}/#{MixPage::URL_SEGMENT}/#{uuid}"].join
  end

  alias_method :old_title, :title
  def title(*args)
    old_title(*args)&.titlefy
  end

  alias_method :old_description, :description
  def description(*args)
    old_description(*args)&.squish
  end

  def default_title
    view.split('/').last.delete_suffix(MixPage::MULTI_VIEW) if view
  end

  def slug(*args)
    title(*args)&.slugify
  end

  def slugs
    I18n.available_locales.map{ |locale| slug(locale) }.compact.uniq
  end

  def slug_exclusion
    I18n.available_locales.each do |locale|
      if MixPage.config.reserved_words.include? slug(locale)
        errors.add :title, :exclusion
      end
    end
  end

  private

  def set_published_at
    self.published_at = publish ? Time.current : nil
  end
end
