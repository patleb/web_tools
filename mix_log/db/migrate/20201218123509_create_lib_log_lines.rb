class CreateLibLogLines < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_log_lines, id: false do |t|
      t.string     :hash_id
      t.integer    :type,       null: false
      t.belongs_to :log,        null: false, index: false, foreign_key: { to_table: :lib_logs }
      t.citext     :message
      t.jsonb      :json_data,  null: false, default: {}
      t.datetime   :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :lib_log_lines, [:hash_id, :type, :log_id, :json_data, :created_at], using: :gin,
      name: 'index_lib_log_lines_on_columns'
  end
end
