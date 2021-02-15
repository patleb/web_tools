class CreateLibServers < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_servers do |t|
      t.integer    :provider,   null: false
      t.inet       :private_ip, null: false
      t.jsonb      :json_data,  null: false, default: {}, index: { using: :gin }
      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime   :deleted_at
    end

    # https://stackoverflow.com/questions/8289100/create-unique-constraint-with-null-columns
    add_index :lib_servers, [:private_ip, :deleted_at, :provider], unique: true,
      name: 'index_lib_servers_on_private_ip_deleted_at_provider', where: 'deleted_at IS NOT NULL'
    add_index :lib_servers, [:private_ip, :provider], unique: true,
      name: 'index_lib_servers_on_private_ip_provider', where: 'deleted_at IS NULL'
  end
end
