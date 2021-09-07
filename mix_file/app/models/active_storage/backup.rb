# frozen_string_literal: true

class ActiveStorage::Backup < ActiveStorage::Record
  self.table_name = 'active_storage_backups'

  belongs_to :blob, class_name: 'ActiveStorage::Blob'
end
