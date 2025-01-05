class CreateTestMuchRecords < ActiveRecord::Migration[8.0]
  def change
    create_partitioned_table :test_much_records do |t|
      t.string  :name, null: false
      t.bigint  :relatable_id
      t.integer :relatable_type
      t.timestamps
    end
  end
end
