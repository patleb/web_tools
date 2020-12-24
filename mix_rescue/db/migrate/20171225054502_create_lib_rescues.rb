class CreateLibRescues < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_rescues, id: false do |t|
      t.primary_key :id, :text
      t.integer     :type,         null: false, default: 0
      t.string      :exception,    null: false
      t.citext      :message,      null: false
      t.bigint      :events_count, null: false, default: 1

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :lib_rescues, [:type, :exception, :created_at]
    add_index :lib_rescues, [:exception, :created_at]
    add_index :lib_rescues, :created_at
  end
end
