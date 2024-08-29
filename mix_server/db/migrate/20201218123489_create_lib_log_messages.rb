class CreateLibLogMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_log_messages do |t|
      t.integer    :log_lines_type,  null: false
      t.bigint     :log_lines_count, null: false, default: 0
      t.string     :text_hash,       null: false
      t.citext     :text_tiny,       null: false
      t.text       :text,            null: false
      t.integer    :level,           null: false
      t.boolean    :monitor # nil --> based on level, false --> never, true --> always
      t.datetime   :line_at,         null: false, default: Time.at(0)
      t.timestamps
    end

    add_index :lib_log_messages, [:log_lines_type, :text_tiny, :level, :monitor, :line_at, :updated_at],
      using: :gin, name: 'index_lib_log_messages_on_columns'
    add_index :lib_log_messages, [:text_hash, :level], unique: true
  end
end
