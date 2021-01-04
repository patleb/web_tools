class GeoIp < LibRecord
  class InvalidIpFormat < ::StandardError; end

  IP_FORMAT = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/

  belongs_to :geo_city, optional: true

  alias_attribute :ip, :id

  def self.find_by_ip(ip)
    where(column(:id) <= ip).order(id: :desc).take
  end

  def self.select_by_ips(ips)
    raise InvalidIpFormat unless ips.all?(&:match?.with(IP_FORMAT))
    connection.exec_query <<-SQL.strip_sql
      SELECT lib_geo_ips.* FROM UNNEST(ARRAY['#{ips.join("','")}']::INET[]) ips(ip)
        LEFT JOIN LATERAL (
          SELECT lib_geo_ips.* FROM lib_geo_ips WHERE id <= ip ORDER BY id DESC LIMIT 1
        ) lib_geo_ips ON TRUE
    SQL
  end
end
