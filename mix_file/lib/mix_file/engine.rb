MonkeyPatch.add{['activestorage', 'lib/active_storage/engine.rb', '46b069b13a4d1332f5f6849a7e854c0400625a5b4e82c3e671277756f1723ef0']}

require 'ext_ruby'
require 'mix_file/configuration'

module MixFile
  class Engine < ::Rails::Engine
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

    initializer 'mix_file.active_record', after: 'active_storage.reflection' do |app|
      ActiveSupport.on_load(:active_record) do
        require 'mix_file/active_record/base/with_file'
      end
    end

    ActiveSupport.on_load(:active_storage_blob) do
      require 'mix_file/active_storage/service/configurator/with_disk_service'
    end
  end
end
