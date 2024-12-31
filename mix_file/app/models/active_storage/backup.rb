class ActiveStorage::Backup < ActiveStorage::Record
  belongs_to :blob, class_name: 'ActiveStorage::Blob'
end
