class CreateLibPageContents < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_page_contents do |t|
      # TODO changes (logidze)
      # TODO active storage --> delete these before deleting content, cell or page
      t.belongs_to :page,         null: false, foreign_key: { to_table: :lib_pages }
      t.belongs_to :page_cell,    foreign_key: { to_table: :lib_page_cells }

      t.integer    :key,          null: false
      t.float      :position,     null: false, limit: 53, default: 0.0

      t.integer    :type,         null: false
      t.jsonb      :json_data,    null: false, default: {}
      t.integer    :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :lib_page_contents, [:page_id, :page_cell_id, :key, :position],
      name: 'index_lib_page_contents_on_page_id_page_cell_id_key_position', unique: true
  end
end
