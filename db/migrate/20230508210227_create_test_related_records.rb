class CreateTestRelatedRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :test_related_records do |t|
      t.string     :name,   null: false, unique: true
      t.belongs_to :record, null: false, foreign_key: { to_table: :test_records }
      t.datetime   :deleted_at
      t.timestamps
      t.userstamps
    end
  end
end
