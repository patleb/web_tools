class GeoCity < LibRecord
  belongs_to :geo_country
  belongs_to :geo_state, optional: true
  has_many   :geo_ips
end
