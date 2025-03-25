MonkeyPatch.add{['activestorage', 'lib/active_storage/engine.rb', '2ab665da0d4ea2b5e8897b9d6fcb738438dfd46a49dc3bb81e61a47213f4bab6']}

require 'ext_rails'
require 'mix_file/configuration'
require 'mix_file/routes'

module MixFile
  class Engine < Rails::Engine
    require 'image_optim'
    require 'image_optim_pack'

    initializer 'mix_file.migrations' do |app|
      append_migrations(app)
    end

    initializer 'mix_file.routes', after: 'active_storage.configs' do
      config.after_initialize do
        ActiveStorage.draw_routes = !!MixFile.config.draw_active_storage_routes
      end
    end

    initializer 'mix_file.disk_service', before: 'active_storage.services' do
      ActiveSupport.on_load(:active_storage_blob) do
        require 'mix_file/active_storage/service/configurator/with_disk_service'
      end
    end

    initializer 'mix_file.active_record', after: 'active_storage.reflection' do
      ActiveSupport.on_load(:active_record) do
        require 'mix_file/active_record/base/with_file'
      end
    end
  end
end
