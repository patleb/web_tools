class CreateLibGeoStates < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_geo_states do |t| # must have an :id as integer, since searchable_id is a bigint
      t.citext      :names,        null: false, array: true
      t.string      :code,         null: false, index: { unique: true }
      t.string      :country_code, null: false
      t.belongs_to  :geo_country,  null: false, foreign_key: { to_table: :lib_geo_countries }
    end

    add_index :lib_geo_states, [:country_code, :names], unique: true,
      name: 'index_lib_geo_states_on_country_code_names'
  end
end
