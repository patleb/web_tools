class CreateActiveStorageBackups < ActiveRecord::Migration[7.1]
  def change
    create_table :active_storage_backups do |t|
      t.belongs_to :blob,       null: false, foreign_key: { to_table: :active_storage_blobs }
      t.binary     :data,       null: false
      t.bigint     :byte_size,  null: false
      t.string     :checksum,   null: false
      t.datetime   :created_at, null: false
    end
  end
end
