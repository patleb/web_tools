module ActiveStorage::Blob::WithBackup
  extend ActiveSupport::Concern

  included do
    has_one :backup, dependent: :destroy, class_name: 'ActiveStorage::Backup'
  end

  def backup_missing?
    !backup_exist?
  end

  def backup_exist?
    ActiveStorage::Backup.exists? blob: self
  end

  def backup_file(io)
    create_backup! data: io.read
    unless Digest::MD5.base64digest(backup.data) == checksum
      backup.destroy!
      raise ActiveStorage::IntegrityError
    end
  end

  def restore_file
    raise 'no backup' unless backup
    # convert data to io, then upload_without_unfurling(io)
  end
end
