class CreateLibUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_users do |t|
      t.uuid     :uuid,            null: false, default: 'gen_random_uuid()', index: { using: :hash }
      # t.citext   :name,            index: { using: :gist, opclass: :gist_trgm_ops }
      # t.string   :login,           index: { unique: true }
      t.string   :email,           null: false, index: { unique: true }
      t.string   :password_digest, null: false
      t.string   :verified_email
      t.datetime :verified_at

      t.integer  :role, null: false, default: 0

      t.jsonb    :json_data, null: false, default: {}, index: { using: :gin }

      t.userstamps
      t.timestamps
      t.datetime :deleted_at
    end

    add_index :lib_users, [:role, :updated_at, :deleted_at]
  end
end
