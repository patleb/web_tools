namespace :page do
  desc 'Create home page'
  task :create_home => :environment do
    layout = PageLayout.find_or_create_by! view: MixPage.config.layout
    template = PageTemplate.find_or_create_by! page_layout: layout, view: MixPage.config.root_template
    template.update! title_en: 'Home', title_fr: 'Accueil', published_at: Time.current
  end

  namespace :images do
    desc 'Replace production base url for development'
    task :prod_to_dev => :environment do
      ssl, host = Setting.with(env: :production, &:values_at.with(:server_ssl, :server))
      prod_url = "http#{'s' if ssl}://#{host}/storage/"
      dev_url = "http://#{Setting[:server]}/storage/"
      PageFields::RichText.all.each do |record|
        texts = I18n.available_locales.map{ |locale| ["text_#{locale}", record["text_#{locale}"]] }.to_h.compact
        next if texts.all?{ |_, text| text.exclude?(prod_url) }
        record.update! texts.transform_values{ |text| text.gsub(prod_url, dev_url) }
      end
    end
  end
end
