# TODO
# https://gist.github.com/phlegx/add77d24ebc57f211e8b
# https://gist.github.com/hadees/cff6af2b53d340b9b4b2
# http://radar.oreilly.com/2014/05/more-than-enough-arel.html
class PageTemplate < Page
  LAYOUTS        = Arel::Table.new(table_name, as: 'layouts')
  MAX_UPDATED_AT = Arel::Nodes::NamedFunction.new('GREATEST', [column(:updated_at), LAYOUTS[:updated_at]], 'updated_at')
  JOIN_LAYOUTS   = arel_table.join(LAYOUTS).on(column(:page_layout_id).eq(LAYOUTS[:id])).join_sources

  belongs_to :page_layout
  belongs_to :layout, -> { merge(PageLayout.with_contents) }, class_name: 'PageLayout', foreign_key: 'page_layout_id'

  validates :view, presence: true
  validates :view, uniqueness: { scope: :page_layout_id }, if: :unique?
  validate  :slug_exclusion

  enum view: MixPage.config.available_templates

  json_translate(
    title: [:string, default: ->(record) { record.default_title }],
    description: [:string, default: ->(record) { record.title }]
  )

  def self.state_of(uuid)
    with_discarded.where(uuid: uuid).joins(JOIN_LAYOUTS)
      .select(:uuid, :view, :json_data, :deleted_at, :published_at, MAX_UPDATED_AT).first
  end

  def publish!
    update! published_at: Time.current.utc
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

  def slug_exclusion
    Rails.application.config.i18n.available_locales.each do |locale|
      if MixPage.config.reserved_words.include? slug(locale)
        errors.add :title, :exclusion
      end
    end
  end
end
