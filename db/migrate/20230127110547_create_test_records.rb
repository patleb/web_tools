class CreateTestRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :test_records do |t|
      t.bigint   :big_integer
      t.boolean  :boolean
      t.date     :date
      t.datetime :datetime
      t.decimal  :decimal
      t.datetime :deleted_at
      t.float    :double
      t.integer  :integer
      t.interval :interval
      t.jsonb    :json
      t.jsonb    :json_data,    null: false, default: {}
      t.integer  :lock_version, null: false, default: 0
      t.string   :password
      t.string   :string, limit: 50
      t.text     :text
      t.time     :time
      t.uuid     :uuid
    end
  end
end
