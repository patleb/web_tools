class CreateLibJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_jobs do |t|
      t.integer     :queue_name,   null: false, default: 0
      t.integer     :priority,     null: false, default: 0
      t.timestamp   :scheduled_at, null: false
      t.jsonb       :json_data,    null: false, default: {}
      t.timestamp   :created_at,   null: false
    end

    add_index :lib_jobs, [:queue_name, :priority, :scheduled_at], order: { priority: :desc }
  end
end
