class CreateLibLogMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_log_messages do |t|
      t.string     :text_hash,       null: false
      t.citext     :text_tiny,       null: false
      t.citext     :text,            null: false
      t.belongs_to :log,             null: false, foreign_key: { to_table: :lib_logs }
      t.integer    :log_lines_type,  null: false
      t.bigint     :log_lines_count, null: false, default: 0
      t.integer    :level,           null: false
      t.boolean    :monitor # nil --> based on level, false --> never, true --> always
      t.boolean    :alerted,         null: false, default: false
      t.citext     :notes
      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :lib_log_messages, [:text_tiny, :log_id, :log_lines_type, :level, :monitor, :alerted, :updated_at],
      using: :gin, name: 'index_lib_log_messages_on_columns'
    add_index :lib_log_messages, [:text_hash, :log_id, :level], unique: true

    if Rails.env.test?
      remove_foreign_key :lib_log_messages, :lib_logs, column: :log_id
    end
  end
end
