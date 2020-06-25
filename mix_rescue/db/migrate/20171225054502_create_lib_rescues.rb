class CreateLibRescues < ActiveRecord::Migration[6.0]
  def up
    unless table_exists? :lib_rescues
      create_table :lib_rescues do |t|
        t.citext   :type,       null: false
        t.citext   :exception,  null: false
        t.citext   :message,    null: false
        t.jsonb    :data,       null: false, default: {}

        t.timestamps
      end

      add_index :lib_rescues, :created_at
      add_index :lib_rescues, [:type, :exception, :message], using: :gin, opclass: { title: :gin_trgm_ops }
    end
  end

  def down
    drop_table :lib_rescues if table_exists? :lib_rescues
  end
end
