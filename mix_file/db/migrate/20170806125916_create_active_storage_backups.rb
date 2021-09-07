class CreateActiveStorageBackups < ActiveRecord::Migration[6.0]
  def change
    create_table :active_storage_backups do |t|
      t.belongs_to :blob,       null: false, foreign_key: { to_table: :active_storage_blobs }
      t.binary     :data,       null: false
      t.datetime   :created_at, null: false
    end
  end
end
