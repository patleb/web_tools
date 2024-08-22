class CreateLibUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_user_sessions, primary_key: [:user_id, :cookie_id] do |t|
      t.belongs_to :user,       null: false, index: false, foreign_key: { to_table: :lib_users }
      t.string     :cookie_id,  null: false
      t.inet       :ip_address, null: false
      t.string     :user_agent, null: false, array: true

      t.timestamps
    end
  end
end