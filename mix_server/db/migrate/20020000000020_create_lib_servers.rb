class CreateLibServers < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_servers do |t|
      t.integer    :provider,   null: false
      t.inet       :private_ip, null: false
      t.jsonb      :json_data,  null: false, default: {}, index: { using: :gin }
      t.timestamps
      t.datetime   :deleted_at
    end

    # https://stackoverflow.com/questions/8289100/create-unique-constraint-with-null-columns
    add_index :lib_servers, [:private_ip, :deleted_at, :provider], unique: true, nulls_not_distinct: true
  end
end
