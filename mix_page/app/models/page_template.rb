class PageTemplate < Page
  belongs_to :page_layout, -> { merge(PageLayout.with_contents) }, counter_cache: :pages_count
  belongs_to :page_template, optional: true, counter_cache: :pages_count
  has_many   :page_templates, dependent: :nullify

  validate  :title_slug_exclusion

  enum view: MixPage.config.available_templates

  json_translate(
    title: [:string, default: ->(record) { record.default_title }],
    description: [:string, default: ->(record) { record.title }]
  )

  alias_attribute :layout, :page_layout

  def publish!
    update! published_at: Time.current.utc
  end

  def unique?
    !view.end_with? MixPage::MULTI_VIEW
  end

  def url(*args)
   "#{title_slug(*args)}/#{MixPage::URL_SEGMENT}/#{uuid}"
  end
  alias_method :to_param, :url

  alias_method :old_title, :title
  def title(*args)
    old_title(*args).titlefy
  end

  alias_method :old_description, :description
  def description(*args)
    old_description(*args).squish
  end

  def default_title
    view.split('/').last.delete_suffix(MixPage::MULTI_VIEW)
  end

  def title_slug(*args)
    title(*args).slugify
  end

  def title_slug_exclusion
    Rails.application.config.i18n.available_locales.each do |locale|
      if MixPage.config.reserved_words.include? title_slug(locale)
        errors.add :title, :exclusion
      end
    end
  end
end
