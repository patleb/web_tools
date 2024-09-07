class CreateLibFlashes < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_flashes do |t|
      t.bigint :user_id,    null: false
      t.string :session_id, null: false
      t.jsonb  :messages,   null: false

      t.timestamps
    end

    add_foreign_key :lib_flashes, :lib_user_sessions, column: [:user_id, :session_id], primary_key: [:user_id, :session_id]
    add_index       :lib_flashes, [:user_id, :session_id, :updated_at]
  end
end
