class CreateLibPageSections < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_page_sections do |t|
      t.float      :position,            null: false, limit: 53
      t.belongs_to :page,                null: false, foreign_key: { to_table: :lib_pages }
      t.belongs_to :page_section,        foreign_key: { to_table: :lib_page_sections }
      t.integer    :page_sections_count, null: false, default: 0
      t.integer    :page_fields_count,   null: false, default: 0
      t.integer    :view,                null: false
      t.integer    :key,                 null: false
      t.integer    :lock_version,        null: false, default: 0
      t.timestamps
    end

    add_index :lib_page_sections, :position, unique: true
    add_index :lib_page_sections, [:page_id, :page_section_id, :key, :position],
      name: 'index_lib_page_sections_on_page_id_page_section_id_key_position', unique: true
  end
end
