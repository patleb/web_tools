class CreateLibPages < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_pages do |t|
      t.integer    :type,                 null: false
      t.uuid       :uuid,                 null: false, default: 'uuid_generate_v1mc()', index: { using: :hash }
      t.decimal    :position,             null: false
      t.belongs_to :page_layout,          foreign_key: { to_table: :lib_pages }
      t.integer    :page_templates_count, null: false, default: 0
      t.integer    :page_fields_count,    null: false, default: 0
      t.integer    :view,                 null: false
      t.jsonb      :json_data,            null: false, default: {}
      t.integer    :lock_version,         null: false, default: 0
      t.userstamps
      t.timestamps
      t.datetime   :deleted_at
      t.datetime   :published_at
    end

    add_index :lib_pages, :position, unique: true
    add_index :lib_pages, [:type, :deleted_at, :position]
  end
end
