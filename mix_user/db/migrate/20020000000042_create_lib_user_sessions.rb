class CreateLibUserSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_user_sessions, primary_key: [:user_id, :session_id] do |t|
      t.belongs_to :user,       null: false, index: false, foreign_key: { to_table: :lib_users }
      t.string     :session_id, null: false
      t.inet       :ip_address, null: false
      t.string     :user_agent, null: false, array: true
      t.jsonb      :json_data,  null: false, default: {}

      t.timestamps
    end
  end
end
