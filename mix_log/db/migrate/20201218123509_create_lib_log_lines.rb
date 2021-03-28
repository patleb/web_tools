### NOTE
# can't have unique index on [:log_id, :created_at], because several workers could write at the same time
# also, if there was a default for :created_at, it could be null on insert and defaults aren't used for uniqueness check
class CreateLibLogLines < ActiveRecord::Migration[6.0]
  def change
    if Rails.env.test?
      create_table :lib_log_lines, id: false do |t|
        t.timestamp :created_at, null: false, default: nil
      end
    else
      reversible do |change|
        change.up do
          exec_query <<-SQL.strip_sql
            CREATE TABLE lib_log_lines (
              created_at TIMESTAMP(6) NOT NULL
            ) PARTITION BY RANGE (created_at);
          SQL
        end
        change.down do
          exec_query "DROP TABLE lib_log_lines CASCADE;"
        end
      end
    end

    change_table :lib_log_lines do |t|
      t.integer    :type,        null: false
      t.belongs_to :log,         null: false,  index: false, foreign_key: { to_table: :lib_logs }
      t.belongs_to :log_message, index: false, foreign_key: { to_table: :lib_log_messages }
      t.integer    :pid
      t.jsonb      :json_data,   null: false, default: {}
    end

    add_index :lib_log_lines, [:created_at, :type, :log_id, :log_message_id, :pid, :json_data], using: :gin,
      name: 'index_lib_log_lines_on_columns'
  end
end
