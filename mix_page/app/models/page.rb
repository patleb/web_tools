class Page < LibMainRecord
  class AlreadyExists < ::StandardError; end

  IMAGE_PATH = /\(([^)]+)\)/
  IMAGE_MD = /!\[[^\]]+\]#{IMAGE_PATH}/
  ORDERING = /^\d+-/

  has_userstamps

  has_many :page_fields, -> { all_discardable.order(:position) }, discardable: :all, dependent: :destroy
  has_many :links, discardable: :all, as: :fieldable, dependent: :destroy, class_name: 'PageFields::Link'

  scope :with_fields, -> { includes(page_fields: :fieldable) }

  enum! :type, {
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

  def self.gsub_assets(text)
    text.gsub(IMAGE_MD) do |match|
      filename = $1
      data = File.open("app/assets/images/#{filename}")
      blob = ActiveStorage::Blob.find_or_create_by_uid! filename, data
      match.sub(IMAGE_PATH, "(blob:#{blob.id})")
    end
  end

  def self.create_home!
    raise AlreadyExists if any?
    layout = PageLayout.find_or_create_by! view: MixPage.config.layout
    template = PageTemplate.find_or_create_by! page_layout: layout, view: MixPage.config.root_template
    titles = I18n.available_locales.map do |l|
      [:"title_#{l}", I18n.t('activerecord.attributes.page/view.home', locale: l)]
    end
    template.update! published_at: Time.current, **titles.to_h
    template
  end

  def self.create_pages!
    raise AlreadyExists if any?
    Dir['app/assets/pages/**/*.md'].sort.each_with_object({}) do |path, templates|
      template = path.delete_prefix('app/assets/pages/')
      template.sub! ORDERING, ''
      template.delete_suffix! '.md'
      template, locale = template.split('.', 2)
      locale ||= I18n.default_locale
      if (multi_view = File.dirname(template)).match? PageTemplate::MULTI_VIEW
        template, multi_name = multi_view, File.basename(template).sub(ORDERING, '')
        i18n_key = "activerecord.attributes.page/view.#{template}/#{multi_name}"
      else
        i18n_key = "activerecord.attributes.page/view.#{template}"
      end
      raise "unavailable template: #{template}" unless MixPage.config.available_templates.has_key? template
      layout = PageLayout.find_or_create_by! view: MixPage.config.layout
      page = templates.dig(layout.view, [template, multi_name])
      page ||= PageTemplate.create! page_layout: layout, view: template
      page.update! "title_#{locale}": I18n.t(i18n_key, locale: locale)
      text = File.read(path)
      text = gsub_assets(text)
      page.content.markdown.update! "text_#{locale}": text
      page.update! published_at: Time.current
      (templates[layout.view] ||= {})[[template, multi_name]] = page
    end
  end
end
