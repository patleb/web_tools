module ActiveStorage::Service::DiskService::WithRmdir
  def delete(key)
    super
    base_dir = File.join(root, folder_for(key))
    begin
      FileUtils.rmdir(base_dir)
      FileUtils.rmdir(File.dirname(base_dir))
    rescue Errno::ENOTEMPTY
      # Ignore not empty dir
    end
  end

  def delete_prefixed(prefix)
    super
    base_dir = path_for(prefix)
    begin
      FileUtils.rmdir(base_dir)
    rescue Errno::ENOTEMPTY
      # Ignore not empty dir
    rescue Errno::ENOENT
      # Ignore files already deleted
    end
  end
end

ActiveStorage::Service::DiskService.prepend ActiveStorage::Service::DiskService::WithRmdir
