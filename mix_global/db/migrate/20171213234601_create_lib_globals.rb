class CreateLibGlobals < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_globals, id: false do |t|
      t.primary_key :id, :string
      t.belongs_to  :server,    null: false, index: false, foreign_key: { to_table: :lib_servers }
      t.boolean     :expires,   null: false, default: false
      t.datetime    :expires_at
      t.string      :version
      t.integer     :data_type, null: false, default: 0
      t.string      :string
      t.jsonb       :json
      t.boolean     :boolean
      t.bigint      :integer
      t.decimal     :decimal
      t.datetime    :datetime
      t.interval    :interval
      t.binary      :serialized

      t.timestamps
    end

    add_index :lib_globals, [:server_id, :expires_at],
      name: "index_lib_globals_on_expirable_expires_at",
      where: '(expires)'
    add_index :lib_globals, [:server_id, :updated_at],
      name: "index_lib_globals_on_expirable_updated_at",
      where: '(expires)'
    add_index :lib_globals, [:server_id, :expires, :updated_at],
      name: "index_lib_globals_on_permanent_updated_at",
      where: '(expires = FALSE)'
  end
end
