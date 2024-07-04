class CreateTestRelatedRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :test_related_records do |t|
      t.string     :name,         null: false
      t.jsonb      :json_data,    null: false, default: {}
      t.belongs_to :record,       null: false, foreign_key: { to_table: :test_records }
      t.decimal    :position,     null: false, index: { unique: true }
      t.integer    :lock_version, null: false, default: 0
      t.datetime   :deleted_at
      t.timestamps
      t.userstamps
    end
  end
end
