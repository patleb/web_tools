class CreateLibLogLines < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_log_lines, id: false do |t|
      t.datetime   :created_at, null: false, precision: 6, default: -> { 'CURRENT_TIMESTAMP' }
      t.integer    :type,       null: false
      t.belongs_to :log,        null: false, index: false, foreign_key: { to_table: :lib_logs }
      t.belongs_to :log_label,  index: false, foreign_key: { to_table: :lib_log_labels }
      t.integer    :pid
      t.jsonb      :json_data,  null: false, default: {}
    end

    add_index :lib_log_lines, [:created_at, :type, :log_id, :log_label_id, :pid, :json_data], using: :gin,
      name: 'index_lib_log_lines_on_columns'

    if Rails.env.test?
      remove_foreign_key :lib_log_lines, :lib_logs, column: :log_id
      remove_foreign_key :lib_log_lines, :lib_log_labels, column: :log_label_id
    end
  end
end
