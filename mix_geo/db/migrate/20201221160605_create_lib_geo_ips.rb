class CreateLibGeoIps < ActiveRecord::Migration[6.0]
  def change
    create_table :lib_geo_ips do |t|
      t.inet       :ip_first,     null: false, index: { unique: true }
      t.inet       :ip_last,      null: false, index: { unique: true }
      t.string     :country_code, null: false
      t.string     :state_code
      t.belongs_to :geo_country,  null: false, foreign_key: { to_table: :lib_geo_countries }
      t.belongs_to :geo_state,    foreign_key: { to_table: :lib_geo_states }
      t.belongs_to :geo_city,     foreign_key: { to_table: :lib_geo_cities }
      t.decimal    :latitude,     null: false
      t.decimal    :longitude,    null: false
    end
  end
end
