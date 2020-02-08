class CreateLibRescues < ActiveRecord::Migration[5.1]
  def up
    drop_table :mr_rescues if table_exists? :mr_rescues

    unless table_exists? :lib_rescues
      create_table :lib_rescues do |t|
        t.string   :type,       null: false
        t.string   :exception,  null: false
        t.text     :message,    null: false
        t.jsonb    :data,       null: false, default: {}

        t.timestamps
      end

      add_index :lib_rescues, [:type, :exception]
      add_index :lib_rescues, :created_at
      add_index :lib_rescues, [:message, :data], using: :gin
    end
  end

  def down
    drop_table :mr_rescues if table_exists? :mr_rescues
    drop_table :lib_rescues if table_exists? :lib_rescues
  end
end
