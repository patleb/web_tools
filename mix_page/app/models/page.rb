class Page < LibMainRecord
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
    layout = PageLayout.find_or_create_by! view: MixPage.config.layout
    template = PageTemplate.find_or_create_by! page_layout: layout, view: MixPage.config.root_template
    titles = I18n.available_locales.map do |l|
      [:"title_#{l}", I18n.t('activerecord.attributes.page/view.home', locale: l)]
    end
    template.update! published_at: Time.current, **titles.to_h
    template
  end
end
