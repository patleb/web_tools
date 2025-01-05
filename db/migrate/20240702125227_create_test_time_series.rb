class CreateTestTimeSeries < ActiveRecord::Migration[8.0]
  def change
    create_partitioned_table :test_time_series, key: :created_at do |t|
      t.integer :type,      null: false
      t.jsonb   :json_data, null: false, default: {}
    end
  end
end
