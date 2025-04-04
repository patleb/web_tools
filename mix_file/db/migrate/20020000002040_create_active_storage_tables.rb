class CreateActiveStorageTables < ActiveRecord::Migration[8.0]
  def change
    create_table :active_storage_blobs do |t|
      t.string   :key,          null: false, index: { unique: true }
      t.string   :filename,     null: false
      t.string   :content_type
      t.jsonb    :metadata,     null: false, default: {}
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum
      t.string   :uid,          index: { using: :hash }
      t.datetime :created_at,   null: false
    end

    create_table :active_storage_attachments do |t|
      t.integer    :name,        null: false
      t.bigint     :record_id,   null: false
      t.integer    :record_type, null: false
      t.belongs_to :blob,        null: false, foreign_key: { to_table: :active_storage_blobs }
      t.datetime   :created_at,  null: false

      t.index [:record_type, :record_id, :name, :blob_id], name: 'index_active_storage_attachments_uniqueness', unique: true
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob,         null: false, foreign_key: { to_table: :active_storage_blobs }, index: false
      t.string :variation_digest, null: false

      t.index [:blob_id, :variation_digest], name: 'index_active_storage_variant_records_uniqueness', unique: true
    end
  end
end
