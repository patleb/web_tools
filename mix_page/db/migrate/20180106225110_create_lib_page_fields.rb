class CreateLibPageFields < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_page_fields do |t|
      t.integer    :type,         null: false
      t.float      :position,     null: false, limit: 53
      t.belongs_to :page,         null: false, foreign_key: { to_table: :lib_pages }
      t.integer    :key,          null: false
      t.bigint     :fieldable_id
      t.integer    :fieldable_type
      t.jsonb      :json_data,    null: false, default: {}
      t.integer    :lock_version, null: false, default: 0
      t.userstamps
      t.timestamps
      t.datetime   :deleted_at
    end

    add_index :lib_page_fields, :position, unique: true
    add_index :lib_page_fields, [:page_id, :key, :position],
      name: 'index_lib_page_fields_on_page_id_key_position', unique: true
    add_index :lib_page_fields, [:fieldable_type, :fieldable_id]
    add_index :lib_page_fields, [:type, :deleted_at, :position]
  end
end
