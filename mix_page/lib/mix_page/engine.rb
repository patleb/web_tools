require 'ext_ruby'
require 'mix_page/configuration'
require 'mix_admin'

module MixPage
  URL_SEGMENT = 'page'.freeze
  MULTI_VIEW = '_multi'.freeze

  class Engine < ::Rails::Engine
    initializer 'mix_page.append_migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_page.append_routes', before: 'ext_rails.append_routes' do |app|
      app.routes.append do
        get "/:slug/#{URL_SEGMENT}/:uuid" => 'pages#show', as: :page
      end
    end
  end
end
