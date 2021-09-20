module ActiveStorage::Blob::WithBackup
  extend ActiveSupport::Concern

  class NoBackup < ::StandardError; end

  included do
    store_accessor :metadata, :backuped

    has_one :backup, dependent: :destroy, class_name: 'ActiveStorage::Backup'
  end

  def backup_missing?
    !backup_exist?
  end

  def backup_exist?
    ActiveStorage::Backup.exists? blob: self
  end

  def backuped?
    backuped
  end

  def backup_file(io)
    create_backup! data: io.read, byte_size: io.size, checksum: checksum
    unless Digest::MD5.base64digest(backup.data) == checksum
      backup.destroy!
      raise ActiveStorage::IntegrityError
    end
    io.rewind
    update! metadata: metadata.merge(backuped: true)
  end

  def restore_file!
    raise NoBackup, "blob id [#{id}]" unless restore_file
  end

  def restore_file
    return false unless backuped?
    io = StringIO.new(backup.data)
    upload_without_unfurling(io)
    update! metadata: metadata.except(:optimized, :gain)
    optimize if optimizable?
    true
  end
end
