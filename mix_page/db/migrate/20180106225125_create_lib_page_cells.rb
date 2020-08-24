class CreateLibPageCells < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_page_cells do |t|
      t.belongs_to :page,                null: false, foreign_key: { to_table: :lib_pages }
      t.belongs_to :page_cell,           foreign_key: { to_table: :lib_page_cells }

      t.integer    :key,                 null: false
      t.integer    :view,                null: false
      t.float      :position,            null: false, limit: 53, default: 0.0

      t.integer    :page_cells_count,    null: false, default: 0
      t.integer    :page_contents_count, null: false, default: 0

      t.integer    :lock_version,        null: false, default: 0
      t.timestamps
    end

    add_index :lib_page_cells, [:page_id, :page_cell_id, :key, :position],
      name: 'index_lib_page_cells_on_page_id_page_cell_id_key_position', unique: true
  end
end
