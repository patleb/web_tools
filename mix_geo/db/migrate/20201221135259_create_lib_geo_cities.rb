class CreateLibGeoCities < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_geo_cities do |t|
      t.citext     :name,         null: false
      t.string     :country_code, null: false
      t.string     :state_code
      t.belongs_to :geo_country,  null: false, foreign_key: { to_table: :lib_geo_countries }
      t.belongs_to :geo_state,    foreign_key: { to_table: :lib_geo_states }
    end

    # https://stackoverflow.com/questions/8289100/create-unique-constraint-with-null-columns
    add_index :lib_geo_cities, [:country_code, :state_code, :name], unique: true,
      name: 'index_lib_geo_cities_on_code_country_state_code_name', where: 'state_code IS NOT NULL'
    add_index :lib_geo_cities, [:country_code, :name], unique: true,
      name: 'index_lib_geo_cities_on_code_country_name', where: 'state_code IS NULL'
  end
end
