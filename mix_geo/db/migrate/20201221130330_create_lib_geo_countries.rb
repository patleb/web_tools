class CreateLibGeoCountries < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_geo_countries do |t| # must have an :id as integer, since counter_cache triggers are used
      t.citext :name, null: false, index: { unique: true }
      t.string :code, null: false, index: { unique: true }
    end
  end
end
