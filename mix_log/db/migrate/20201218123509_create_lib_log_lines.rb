### NOTE
# can't have unique index on [:log_id, :created_at], because several workers could write at the same time
# also, if there was a default for :created_at, it could be null on insert and defaults aren't used for uniqueness check
class CreateLibLogLines < ActiveRecord::Migration[6.0]
  def change
    create_table_sql{ "CREATE TABLE lib_log_lines (created_at TIMESTAMP(6) NOT NULL) PARTITION BY RANGE (created_at)" }

    change_table :lib_log_lines do |t|
      t.integer    :type,        null: false
      t.belongs_to :log,         null: false,  index: false, foreign_key: false
      t.belongs_to :log_message, index: false, foreign_key: false
      t.integer    :pid
      t.jsonb      :json_data,   null: false, default: {}
    end

    unless ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables
      add_foreign_key :lib_log_lines, :lib_logs, column: :log_id
      add_foreign_key :lib_log_lines, :lib_log_messages, column: :log_message_id
    end

    add_index :lib_log_lines, [:created_at, :type, :log_id, :log_message_id, :pid, :json_data], using: :gin,
      name: 'index_lib_log_lines_on_columns'
  end
end
