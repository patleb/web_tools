class CreateLibGeoCities < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_geo_cities do |t|
      t.citext :name,         null: false
      t.string :country_code, null: false
      t.string :state_code,   null: false, default: ''
    end

    add_index :lib_geo_cities, [:country_code, :state_code, :name], unique: true
  end
end
