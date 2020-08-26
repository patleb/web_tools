class PageTemplate < Page
  belongs_to :page_layout
  belongs_to :layout, -> { merge(PageLayout.with_contents) }, optional: true, class_name: 'PageLayout'

  validates :view, presence: true
  validates :view, uniqueness: { scope: :page_layout_id }, if: :unique?
  validate  :title_slug_exclusion

  enum view: MixPage.config.available_templates

  json_translate(
    title: [:string, default: ->(record) { record.default_title }],
    description: [:string, default: ->(record) { record.title }]
  )

  def publish!
    update! published_at: Time.current.utc
  end

  def published?
    published_at&.past?
  end

  def unique?
    view && !view.end_with?(MixPage::MULTI_VIEW)
  end

  def to_url(*args)
   host = Rails.application.routes.default_url_options[:host]
   port = Rails.application.routes.default_url_options[:port]
   protocol = "http#{'s' if Rails.application.config.force_ssl}://"
   [protocol, host, (':' if port), port, "/#{title_slug(*args)}/#{MixPage::URL_SEGMENT}/#{uuid}"].join
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

  def title_slug(*args)
    title(*args)&.slugify
  end

  def title_slug_exclusion
    Rails.application.config.i18n.available_locales.each do |locale|
      if MixPage.config.reserved_words.include? title_slug(locale)
        errors.add :title, :exclusion
      end
    end
  end
end
