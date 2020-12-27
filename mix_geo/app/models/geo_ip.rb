class GeoIp < LibRecord
  belongs_to :geo_country
  belongs_to :geo_state, optional: true
  belongs_to :geo_city, optional: true

  def self.find_by_ip(ip)
    where(column(:ip_first) <= ip).order(ip_first: :desc).take
  end
end
