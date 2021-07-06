class CreateLibLogRollups < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_log_rollups, id: false do |t|
      t.integer    :type,        null: false
      t.belongs_to :log,         null: false, index: false, foreign_key: { to_table: :lib_logs }
      t.integer    :group_name,  null: false
      t.string     :group_value, null: false, default: ''
      t.interval   :period,      null: false
      t.datetime   :period_at,   null: false
      t.jsonb      :json_data,   null: false, default: {}
    end

    add_index :lib_log_rollups, [:log_id, :type, :group_name, :group_value, :period, :period_at], unique: true,
      name: 'index_lib_log_rollups_on_groups'
    add_index :lib_log_rollups, [:log_id, :type, :group_name, :group_value, :period, :period_at, :json_data], using: :gin,
      name: 'index_lib_log_rollups_on_columns'
  end
end
