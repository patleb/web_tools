Secret.class_eval do
  def self.geoserver_url
    "http#{'s' if self[:geoserver_ssl]}://#{geoserver_server}/geoserver"
  end

  def self.pgrest_url
    "http#{'s' if self[:pgrest_server_ssl]}://#{pgrest_server}"
  end

  def self.pgrest_db_uri
    database_url(self[:pgrest_db_username], self[:pgrest_db_password])
  end

  def self.database_url(user = self[:db_username], pwd = self[:db_password])
    "postgresql://#{user}:#{pwd}@#{self[:db_host] || '127.0.0.1'}:#{self[:db_port] || 5432}/#{self[:db_database]}"
  end

  def self.geoserver_server
    [self[:geoserver_host], self[:geoserver_port]].compact.join(':')
  end

  def self.pgrest_server
    [self[:pgrest_server_host], self[:pgrest_server_port]].compact.join(':')
  end

  def self.server
    [self[:server_host], self[:server_port]].compact.join(':')
  end
end
