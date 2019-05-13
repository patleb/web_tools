Secret.class_eval do
  def self.database_url
    user, pwd, host, port, db = values_at(:db_username, :db_password, :db_host, :db_port, :db_database)
    "postgresql://#{user}:#{pwd}@#{host}:#{port || 5432}/#{db}"
  end

  def self.server
    [self[:server_host], self[:server_port]].compact.join(':')
  end
end
