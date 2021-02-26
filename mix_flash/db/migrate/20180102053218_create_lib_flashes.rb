class CreateLibFlashes < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_flashes, unlogged: true do |t|
      t.belongs_to :user,       null: false, index: false, foreign_key: { to_table: :lib_users }
      t.string     :session_id, null: false
      t.jsonb      :messages,   null: false

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :lib_flashes, [:user_id, :session_id, :updated_at]
  end
end
