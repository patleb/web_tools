class CreateTestRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :test_records do |t|
      t.boolean  :boolean
      t.date     :date
      t.datetime :date_time
      t.decimal  :decimal
      t.datetime :deleted_at
      t.integer  :integer
      t.jsonb    :json
      t.integer  :lock_version, null: false, default: 0
      t.string   :password
      t.string   :string
      t.text     :text
      t.time     :time
      t.uuid     :uuid
    end
  end
end
