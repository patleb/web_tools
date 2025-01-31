require 'mix_page/configuration'
require 'mix_page/routes'
require 'mix_file'
require 'mix_admin'

module MixPage
  class Engine < ::Rails::Engine
    initializer 'mix_page.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_page.routes', before: 'ext_rails.routes' do |app|
      app.routes.append do
        MixPage::Routes.draw(self)
      end
    end

    initializer 'mix_page.admin' do
      MixAdmin.configure do |config|
        config.root_model_name = 'PageTemplate'
        config.included_models += %w(
          PageTemplate
          PageField
          PageFieldMarkdown
          PageFields::%
        )
      end
    end

    ActiveSupport.on_load(:active_record) do
      MixServer::Logs.config.ided_paths[%r{/(#{MixPage::Routes::FRAGMENT})/([\w-]+)}] = '/\1/*'

      MixFile.configure do |config|
        config.available_records['PageFieldMarkdown'] = 10
        config.available_associations[:images] = 100
      end
    end
  end
end
