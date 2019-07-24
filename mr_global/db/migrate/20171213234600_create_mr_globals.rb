class CreateMrGlobals < ActiveRecord::Migration[5.1]
  def change
    create_table :mr_globals, id: false do |t|
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

    add_index :mr_globals, [:expires_at],
      name: "index_mr_globals_on_expirable_expires_at",
      where: '(expires)'
    add_index :mr_globals, [:updated_at],
      name: "index_mr_globals_on_expirable_updated_at",
      where: '(expires)'
    add_index :mr_globals, [:expires, :updated_at],
      name: "index_mr_globals_on_permanent_updated_at",
      where: '(expires = FALSE)'
  end
end
