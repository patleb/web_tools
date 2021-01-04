class CreateLibGeoIps < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_geo_ips, id: false do |t|
      t.primary_key :id, :inet
      t.string      :country_code, null: false
      t.string      :state_code
      t.belongs_to  :geo_city,     index: false, foreign_key: { to_table: :lib_geo_cities }
      t.point       :coordinates,  null: false
    end
  end
end
