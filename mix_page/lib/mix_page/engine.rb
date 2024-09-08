require 'mix_page/configuration'
require 'mix_file'
require 'mix_admin'

module MixPage
  URL_SEGMENT = 'page'.freeze
  MULTI_VIEW = %r{[/_]multi$}

  def self.routes
    @routes ||= {
      show: "/__SLUG__/#{URL_SEGMENT}/__UUID__",
      field_create: "/#{URL_SEGMENT}/__UUID__/field",
      field_update: "/#{URL_SEGMENT}/__UUID__/field/__ID__",
    }
  end

  def self.root_path
    if MixPage.config.root_path.present?
      MixPage.config.root_path
    elsif (root_page = PageTemplate.find_root_page)&.show?
      root_page.to_url
    end
  end

  class Engine < ::Rails::Engine
    initializer 'mix_page.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_page.routes', before: 'ext_rails.routes' do |app|
      app.routes.append do
        get "/:slug/#{URL_SEGMENT}(/:uuid)" => 'pages#show', as: :page
        post "/#{URL_SEGMENT}/:uuid/field" => 'pages#field_create', as: :page_field
        patch "/#{URL_SEGMENT}/:uuid/field/:id" => 'pages#field_update', as: :edit_page_field
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixServer::Log.config.ided_paths[%r{/(#{URL_SEGMENT})/([\w-]+)}] = '/\1/*'

      MixFile.configure do |config|
        config.available_records['PageFields::RichText'] = 10
        config.available_associations['images'] = 100
      end
    end
  end
end
