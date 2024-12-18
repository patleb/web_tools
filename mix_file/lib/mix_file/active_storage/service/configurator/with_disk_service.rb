MonkeyPatch.add{['activestorage', 'lib/active_storage/service/configurator.rb', '40e29021310cf0d01a1f0fcb2b4256176012ee5d97582a6efa06f53e9e160bd1']}
MonkeyPatch.add{['activestorage', 'lib/active_storage/service/disk_service.rb', '42074d2366a37d6dbb84a883ce5ddf9417c44b3ec2f9df9280ee102c965b6774']}

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
