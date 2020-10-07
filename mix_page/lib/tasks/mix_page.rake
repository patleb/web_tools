namespace :page do
  desc 'Prepare'
  task :prepare => :environment do
    layout = PageLayout.find_or_create_by! view: MixPage.config.layout
    template = PageTemplate.find_or_create_by! page_layout: layout, view: 'home'
    template.update! title_en: 'Home', title_fr: 'Accueil', published_at: Time.current
  end
end
