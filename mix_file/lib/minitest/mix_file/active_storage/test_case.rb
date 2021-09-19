module ActiveStorage
  class TestCase < ActiveSupport::TestCase
    def after_teardown
      super
      case ActiveStorage::Blob.service.class.name
      when 'ActiveStorage::Service::MirrorService'
        ([ActiveStorage::Blob.service.primary] + ActiveStorage::Blob.service.mirrors).each do |service|
          FileUtils.rm_rf(service.root)
        end
      when 'ActiveStorage::Service::DiskService'
        FileUtils.rm_rf(ActiveStorage::Blob.service.root)
      end
    end
  end
end
