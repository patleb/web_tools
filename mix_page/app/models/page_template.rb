class PageTemplate < Page
  MULTI_VIEW = %r{[/_]multi$}

  belongs_to :page_layout

  validates :view, presence: true
  validates :view, uniqueness: { scope: :page_layout_id }, if: -> { view_changed? && unique? }
  I18n.available_locales.each do |locale|
    validates "title_#{locale}", length: { maximum: 120 }
    validates "description_#{locale}", length: { maximum: 360 }
  end

  enum! :view, MixPage.config.available_templates

  json_translate(
    title: [:string, default: ->(record) { record.default_title }],
    description: [:string, default: ->(record) { record.title }]
  )

  alias_attribute :layout_id, :page_layout_id

  attr_writer :publish

  before_validation :set_published_at, if: :publish_changed?
  before_validation :set_page_layout, unless: :page_layout_id

  after_create :create_sidebar unless MixPage.config.skip_sidebar
  after_create :create_content unless MixPage.config.skip_content

  after_discard -> { update! published_at: nil }

  # NOTE has_many polymorhic association not implemented in admin and field name is only available in actual pages
  # accepts_nested_attributes_for :links

  def self.available_views
    uniques = MixPage.config.available_templates.keys.reject{ |key| key.match?(MULTI_VIEW) }
    taken = with_discarded.where(view: uniques).distinct.pluck(:view).map(&:to_s)
    MixPage.config.available_templates.reject{ |key, _| taken.include? key }
  end

  def self.find_root_page
    (view = MixPage.config.root_template) && find_by(view: view)
  end

  def self.find_with_state_by_uuid_or_view(uuid, slug)
    conditions =  uuid.present? ? { uuid: UUID.expand(uuid) } : { view: (view = slug.sub(/-[a-z]{2}$/, '').tr('-', '/')) }
    return unless view.nil? || views.has_key?(view)
    layouts = alias_table(:layouts)
    select(:id, :uuid, :view, :json_data, :deleted_at, :published_at, greatest(:updated_at, layouts[:updated_at]))
      .where(conditions).joins(join(layouts).on(column(:page_layout_id).eq(layouts[:id])).join_sources)
      .take
  end

  def uuid
    UUID.shorten(self[:uuid])
  end

  # NOTE no support for multiple layouts --> MixPage.config.layout
  def layout
    @layout ||= PageLayout.with_fields.readonly.find(page_layout_id)
  end

  def template
    "pages/#{view}"
  end

  def show?
    published? || Current.user.admin?
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
    view && !view.match?(MULTI_VIEW)
  end

  def to_url(...)
    MixPage::Routes.page_path(slug: slug(...), uuid: uuid)
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
    self.class.human_attribute_name("view.#{view}", default: view.to_s.sub(MULTI_VIEW, '').tr('/', ' ').humanize)
  end

  def slug(locale = nil, fallback = nil)
    locale ||= Current.locale
    value = title(locale, fallback)&.slugify
    [value, locale].join('-') if value
  end

  def slugs
    I18n.available_locales.map{ |locale| slug(locale) }.compact.uniq
  end

  def sidebar
    links.where(name: :sidebar).take
  end

  def content
    page_fields.where(name: :content).take
  end

  private

  def set_published_at
    self.published_at = publish ? Time.current : nil
  end

  def set_page_layout
    self.page_layout = PageLayout.find_or_create_by! view: MixPage.config.layout
  end

  def create_sidebar
    links.create! name: :sidebar, page: page_layout
  end

  def create_content
    page_fields.create! name: :content, type: 'PageFields::Html'
  end
end
