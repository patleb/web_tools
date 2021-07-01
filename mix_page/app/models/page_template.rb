class PageTemplate < Page
  belongs_to :page_layout
  has_many   :links, -> { with_discarded }, as: :fieldable, dependent: :destroy, class_name: 'PageFields::Link'

  validates :view, presence: true
  validates :view, uniqueness: { scope: :page_layout_id }, if: -> { view_changed? && unique? }
  validate  :slug_exclusion
  validate  :slug_scoped_by_locale
  I18n.available_locales.each do |locale|
    validates "title_#{locale}", length: { maximum: 120 }
    validates "description_#{locale}", length: { maximum: 360 }
  end

  enum view: MixPage.config.available_templates

  json_translate(
    title: [:string, default: ->(record) { record.default_title }],
    description: [:string, default: ->(record) { record.title }]
  )

  attr_writer :publish

  before_validation :set_published_at, if: :publish_changed?
  before_validation :set_page_layout, unless: :page_layout_id

  after_create :create_sidebar_link unless MixPage.config.skip_sidebar_link

  after_discard -> { update! published_at: nil }
  after_discard -> { discard_all! :links }
  before_undiscard -> { undiscard_all! :links }

  # NOTE has_many polymorhic association not implemented in admin and field name is only available in actual pages
  # accepts_nested_attributes_for :links

  def self.available_views
    uniques = MixPage.config.available_templates.keys.reject{ |key| key.match?(MixPage::MULTI_VIEW) }
    taken = with_discarded.where(view: uniques).distinct.pluck(:view)
    MixPage.config.available_templates.reject{ |key, _| key.in? taken }
  end

  def self.find_root_page
    return unless (view = MixPage.config.root_template)
    with_discarded.find_by(view: view)
  end

  def self.find_with_state_by_uuid_or_view(uuid, slug)
    conditions =  uuid.present? ? { uuid: UUID.expand(uuid) } : { view: (view = slug.tr('-', '/')) }
    return unless view.nil? || views.has_key?(view)
    layouts = alias_table(:layouts)
    with_discarded
      .where(conditions).joins(join(layouts).on(column(:page_layout_id).eq(layouts[:id])).join_sources)
      .select(:id, :uuid, :view, :json_data, :deleted_at, :published_at, greatest(:updated_at, layouts[:updated_at]))
      .first
  end

  def self.find_with_content(id)
    with_discarded.with_content.find(id)
  end

  def uuid
    UUID.shorten(self[:uuid])
  end

  def layout
    @layout ||= PageLayout.with_content.readonly.find(page_layout_id)
  end

  def template
    "pages/#{view}"
  end

  def show?
    super && (published? || Current.user&.admin?)
  end

  def publish
    @publish.nil? ? published? : @publish.to_b
  end

  def publish_changed?
    !@publish.nil? && published? != @publish.to_b
  end

  def published?
    published_at&.past?.to_b
  end

  def unique?
    view && !view.match?(MixPage::MULTI_VIEW)
  end

  def to_url(...)
   host = Rails.application.routes.default_url_options[:host]
   port = Rails.application.routes.default_url_options[:port]
   protocol = "http#{'s' if Setting[:server_ssl]}://"
   [protocol, host, (':' if port), port, "/#{slug(...)}/#{MixPage::URL_SEGMENT}/#{uuid}"].join
  end

  alias_method :old_title, :title
  def title(...)
    old_title(...)&.humanize
  end

  alias_method :old_description, :description
  def description(...)
    old_description(...)&.squish
  end

  def default_title
    return unless view
    self.class.human_attribute_name("view.#{view}", default: view.sub(MixPage::MULTI_VIEW, '').tr('/', ' ').humanize)
  end

  def slug(...)
    title(...)&.slugify
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

  def slug_scoped_by_locale
    if I18n.available_locales.size != slugs.size
      errors.add :title, :taken
    end
  end

  private

  def set_published_at
    self.published_at = publish ? Time.current : nil
  end

  def set_page_layout
    self.page_layout = PageLayout.find_or_create_by! view: MixPage.config.layout
  end

  def create_sidebar_link
    PageFields::Link.create! page_id: page_layout_id, name: :sidebar_links, fieldable: self
  end
end
