class CreateLibPageFields < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_page_fields do |t|
      # TODO changes (logidze)
      # TODO active storage --> delete these before deleting content, section or page
      t.float      :position,     null: false, limit: 53, default: 1.0
      t.belongs_to :page,         null: false, foreign_key: { to_table: :lib_pages }
      t.belongs_to :page_section, foreign_key: { to_table: :lib_page_sections }
      t.integer    :key,          null: false

      t.integer    :type,         null: false
      t.jsonb      :json_data,    null: false, default: {}
      t.integer    :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :lib_page_fields, [:page_id, :page_section_id, :key, :position],
      name: 'index_lib_page_fields_on_page_id_page_section_id_key_position', unique: true
  end
end
