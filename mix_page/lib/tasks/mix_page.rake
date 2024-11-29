namespace! :page do
  desc 'Create home page'
  task :create_home => :environment do
    Page.create_home!
  end

  namespace :images do
    desc 'Replace production base url for development'
    task :prod_to_dev => :environment do
      from_url = base_url :production
      to_url = base_url :development
      convert_fields from_url, to_url
    end

    desc 'Replace production base url for staging'
    task :prod_to_staging => :environment do
      from_url = base_url :production
      to_url = base_url :staging
      convert_fields from_url, to_url
    end

    desc 'Replace staging base url for development'
    task :staging_to_dev => :environment do
      from_url = base_url :staging
      to_url = base_url :development
      convert_fields from_url, to_url
    end
  end

  def convert_fields(from_url, to_url)
    PageFields::RichText.all.each do |record|
      texts = I18n.available_locales.map{ |locale| ["text_#{locale}", record["text_#{locale}"]] }.to_h.compact
      next if texts.all?{ |_, text| text.exclude?(from_url) }
      record.update! texts.transform_values{ |text| text.gsub(from_url, to_url) }
    end
  end

  def base_url(environment)
    ssl, host = Setting.with(env: environment, &:values_at.with(:server_ssl, :server))
    "http#{'s' if ssl}://#{host}/storage/"
  end
end
