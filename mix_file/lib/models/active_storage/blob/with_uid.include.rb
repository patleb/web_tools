module ActiveStorage::Blob::WithUid
  extend ActiveSupport::Concern

  included do
    validates :uid, presence: true, unless: :composed
  end

  class_methods do
    def find_or_create_by_uid!(filename, data, backup: true, **)
      uid = uid_for(filename, data)
      if (blob = ActiveStorage::Blob.find_by(uid: uid))
        blob.backup_file(data) if backup && !blob.backuped?
      else
        blob = ActiveStorage::Blob.build_after_unfurling(io: data, filename: filename, **)
        blob.uid = uid
        blob.save!
        blob.backup_file(data) if backup
        blob.upload_without_unfurling(data)
      end
      blob
    end

    private

    def uid_for(filename, data)
      [uid_filename_digest(filename), uid_data_digest(data)].join(',')
    end

    def uid_filename_digest(filename)
      Base64.strict_encode64(filename)
    end

    def uid_data_digest(data)
      raise ArgumentError, 'data must be rewindable' unless data.respond_to? :rewind
      sha = Digest::SHA2.new
      chunk = ''.b
      while data.read(5.megabytes, chunk)
        sha << chunk
      end
      data.rewind
      sha.base64digest
    end
  end
end
