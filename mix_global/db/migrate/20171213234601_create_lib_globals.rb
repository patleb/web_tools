class CreateLibGlobals < ActiveRecord::Migration[6.0]
  def up
    unless table_exists? :lib_globals
      create_table :lib_globals, id: false do |t|
        t.primary_key :id, :text
        t.boolean     :expires,   null: false, default: false
        t.datetime    :expires_at
        t.text        :version
        t.integer     :data_type, null: false, default: 0
        t.text        :text
        t.jsonb       :json
        t.boolean     :boolean
        t.bigint      :integer
        t.decimal     :decimal
        t.datetime    :datetime
        t.interval    :interval
        t.binary      :serialized

        t.timestamps
      end

      add_index :lib_globals, [:expires_at],
        name: "index_lib_globals_on_expirable_expires_at",
        where: '(expires)'
      add_index :lib_globals, [:updated_at],
        name: "index_lib_globals_on_expirable_updated_at",
        where: '(expires)'
      add_index :lib_globals, [:expires, :updated_at],
        name: "index_lib_globals_on_permanent_updated_at",
        where: '(expires = FALSE)'
    end
  end

  def down
    drop_table :lib_globals if table_exists? :lib_globals
  end
end
