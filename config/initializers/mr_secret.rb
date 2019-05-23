Secret.class_eval do
  def self.pgrest_uri
    database_url(self[:pgrest_username], self[:pgrest_password])
  end

  def self.database_url(user = self[:db_username], pwd = self[:db_password])
    "postgresql://#{user}:#{pwd}@#{self[:db_host] || '127.0.0.1'}:#{self[:db_port] || 5432}/#{self[:db_database]}"
  end

  def self.server
    [self[:server_host], self[:server_port]].compact.join(':')
  end
end
