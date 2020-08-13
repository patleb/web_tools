class CreateLibRescues < ActiveRecord::Migration[6.0]
  def up
    create_table :lib_rescues, id: false do |t|
      t.primary_key :id, :text
      t.citext      :type,         null: false
      t.citext      :exception,    null: false
      t.citext      :message,      null: false
      t.jsonb       :data,         null: false, default: {}
      t.bigint      :events_count, null: false, default: 1

      t.timestamps
    end

    add_index :lib_rescues, :created_at
    add_index :lib_rescues, [:type, :exception, :message], using: :gin, opclass: { title: :gin_trgm_ops }
  end

  def down
    drop_table :lib_rescues
  end
end
