class DeviseCreateLibUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: "", limit: 128

      # Encryptable
      t.string :password_salt,      null: false, default: "", limit: 128

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      ## Role
      t.integer :role, null: false, default: 0

      ## Data
      t.jsonb :json_data, null: false, default: {}

      t.userstamps
      t.timestamps
      t.datetime :deleted_at
    end

    add_index :lib_users, :email,                unique: true
    add_index :lib_users, :reset_password_token, unique: true
    add_index :lib_users, :confirmation_token,   unique: true
    add_index :lib_users, :unlock_token,         unique: true
    add_index :lib_users, [:role, :updated_at, :deleted_at]
    add_index :lib_users, :json_data, using: :gin
  end
end
