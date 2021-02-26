class CreateLibCredentials < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_credentials, id: false do |t|
      t.primary_key :id, :text
      t.integer     :type,      null: false
      t.string      :token
      t.string      :challenge
      t.datetime    :expires_at
      t.jsonb       :json_data, null: false, default: {}, index: { using: :gin }

      t.timestamps
    end

    add_index :lib_credentials, [:type, :updated_at]
  end
end
