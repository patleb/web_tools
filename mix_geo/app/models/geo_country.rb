class GeoCountry < LibRecord
  has_many :geo_states
  has_many :geo_cities
  has_many :geo_ips
end
