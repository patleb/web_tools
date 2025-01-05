class CreateLibGeoCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :lib_geo_countries do |t|
      t.citext :name, null: false, index: { unique: true }
      t.string :code, null: false, index: { unique: true }
    end
  end
end
