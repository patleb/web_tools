class CreateLibUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :lib_users do |t|
      t.uuid     :uuid,            null: false, default: 'gen_random_uuid()', index: { using: :hash }
      t.string   :email,           null: false, index: { unique: true }
      t.string   :password_digest, null: false
      t.string   :verified_email
      t.datetime :verified_at

      t.citext   :full_name, index: { using: :gist, opclass: :gist_trgm_ops }
      t.integer  :last_name_i

      t.integer  :role, null: false, default: 0

      t.jsonb    :json_data, null: false, default: {}, index: { using: :gin }

      t.userstamps
      t.timestamps
      t.datetime :deleted_at
    end

    add_index :lib_users, [:role, :updated_at, :deleted_at]
  end
end
