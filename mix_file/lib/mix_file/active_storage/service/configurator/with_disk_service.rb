module ActiveStorage::Service::Configurator::WithDiskService
  private

  def resolve(class_name)
    service = super
    if service.name == 'ActiveStorage::Service::DiskService'
      require 'mix_file/active_storage/service/disk_service/with_public_url'
      require 'mix_file/active_storage/service/disk_service/with_rmdir'
    end
    service
  end
end

ActiveStorage::Service::Configurator.prepend ActiveStorage::Service::Configurator::WithDiskService
