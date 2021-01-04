class CreateLibGeoCities < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_geo_cities do |t|
      t.citext :name,         null: false
      t.string :country_code, null: false
      t.string :state_code
    end

    # TODO maybe use a common null value like '-', so 2 indexes won't be necessary
    # https://stackoverflow.com/questions/8289100/create-unique-constraint-with-null-columns
    add_index :lib_geo_cities, [:country_code, :state_code, :name], unique: true,
      name: 'index_lib_geo_cities_on_country_code_state_code_name', where: 'state_code IS NOT NULL'
    add_index :lib_geo_cities, [:country_code, :name], unique: true,
      name: 'index_lib_geo_cities_on_country_code_name', where: 'state_code IS NULL'
  end
end
