class CreateLibLogUnknowns < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_log_unknowns do |t|
      t.integer    :log_lines_type,  null: false
      t.bigint     :log_lines_count, null: false, default: 0
      t.string     :text_hash,       null: false, index: { unique: true }
      t.text       :text,            null: false
      t.timestamps
    end

    add_index :lib_log_unknowns, :updated_at
  end
end
