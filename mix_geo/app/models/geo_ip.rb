class GeoIp < LibRecord
  belongs_to :geo_city, optional: true

  alias_attribute :ip, :id

  def self.find_by_ip(ip)
    where(column(:id) <= ip).order(id: :desc).take
  end

  def self.select_by_ips(ips)
    connection.exec_query(sanitize_sql_array([<<-SQL.strip_sql, ips]))
      SELECT #{table_name}.* FROM UNNEST(ARRAY[?]::INET[]) ips(ip)
        LEFT JOIN LATERAL (
          SELECT #{table_name}.* FROM #{table_name} WHERE id <= ip ORDER BY id DESC LIMIT 1
        ) #{table_name} ON TRUE
    SQL
  end
end
