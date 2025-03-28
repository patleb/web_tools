class Page < LibMainRecord
  IMAGE_PATH = /\(([\/\w.-]+)\)/
  IMAGE_MD = /!\[[^\]]+\]#{IMAGE_PATH}/

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

  def self.create_home!
    return if Rails.env.production?
    layout = PageLayout.find_or_create_by! view: MixPage.config.layout
    template = PageTemplate.find_or_create_by! page_layout: layout, view: MixPage.config.root_template
    titles = I18n.available_locales.map do |l|
      [:"title_#{l}", I18n.t('activerecord.attributes.page/view.home', locale: l)]
    end
    template.update! published_at: Time.current, **titles.to_h
    template
  end

  # TODO gems support and granular production check
  def self.create_pages!
    return if Rails.env.production?
    Dir['app/assets/markdowns/**/*.md'].each_with_object([]) do |path, templates|
      layout, template = path.delete_prefix('app/assets/markdowns/').split('/', 2)
      raise "unavailable layout: #{layout}" unless MixPage.config.available_layouts.has_key? layout
      template.delete_suffix! '.md'
      template, locale = template.split('.', 2)
      locale ||= I18n.default_locale
      i18n_key = "activerecord.attributes.page/view.#{template}"
      if (multi_view = File.dirname(template)).match? PageTemplate::MULTI_VIEW
        template, multi_view = multi_view, File.basename(template)
      end
      raise "unavailable template: #{template}" unless MixPage.config.available_templates.has_key? template
      layout = PageLayout.find_or_create_by! view: layout
      template = PageTemplate.find_or_create_by! page_layout: layout, view: template
      template.update! "title_#{locale}": I18n.t(i18n_key, locale: locale)
      text = File.read(path)
      text = text.gsub(IMAGE_MD) do |match|
        filename = $1
        data = File.open("app/assets/images/#{filename}")
        blob = ActiveStorage::Blob.find_or_create_by_uid! filename, data
        match.sub(IMAGE_PATH, "(blob:#{blob.id})")
      end
      markdown = template.content.markdown
      markdown.update! "text_#{locale}": text
      template.update! published_at: Time.current
      templates << template
    end
  end
end
