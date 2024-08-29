class CreateLibLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_logs do |t|
      t.belongs_to :server,          null: false, index: false, foreign_key: { to_table: :lib_servers }
      t.string     :path,            null: false, default: ''
      t.bigint     :line_i,          null: false, default: 0
      t.datetime   :mtime,           null: false, default: Time.at(0)
      t.integer    :log_lines_type,  null: false
      t.bigint     :log_lines_count, null: false, default: 0
      t.timestamps
    end

    add_index :lib_logs, [:server_id, :path, :log_lines_type], unique: true
  end
end
