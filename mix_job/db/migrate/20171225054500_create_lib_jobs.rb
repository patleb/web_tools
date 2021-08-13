class CreateLibJobs < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_jobs, id: false do |t|
      t.primary_key :id, :uuid,    null: false, default: 'uuid_generate_v1mc()'
      t.integer     :queue_name,   null: false, default: 0
      t.integer     :priority,     null: false, default: 0
      t.timestamp   :scheduled_at, null: false
      t.jsonb       :json_data,    null: false, default: {}
      t.timestamp   :created_at,  null: false
    end

    add_index :lib_jobs, [:queue_name, :priority, :scheduled_at], order: { priority: :desc }
  end
end
