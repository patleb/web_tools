require 'ext_ruby'
require 'mix_file/configuration'

module MixFile
  class Engine < ::Rails::Engine
    # require 'active_storage_validations'
    # require 'activestorage-validator'
    require 'image_optim'
    require 'image_optim_pack'

    initializer 'mix_file.migrations' do |app|
      append_migrations(app)
    end

    # initializer 'mix_file.services', after: 'active_storage.services' do |app|
    #   ActiveSupport.on_load(:active_storage_blob) do
    #     if ActiveStorage::Blob.service.try(:public_root)
    #       ActiveStorage.draw_routes = app.config.active_storage.draw_routes = false
    #     else
    #       app.config.active_storage.routes_prefix = '/storage'
    #     end
    #   end
    # end

    ActiveSupport.on_load(:active_record) do
      require 'mix_file/active_record/base/with_file'
    end

    ActiveSupport.on_load(:active_storage_blob) do
      require 'mix_file/active_storage/service/configurator/with_disk_service'
    end
  end
end
