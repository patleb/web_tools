class GeoCountry < LibRecord
  self.primary_key = :id

  has_many :geo_states
  has_many :geo_cities
  has_many :geo_ips
end
