Setting.class_eval do
  def self.geoserver_private_url
    "http://#{geoserver_private_server}/geoserver"
  end

  def self.geoserver_url
    "http://#{geoserver_server}/geoserver"
  end

  def self.pgrest_url
    url = "http#{'s' if self[:pgrest_server_ssl]}://#{pgrest_server}"
    url = [url, self[:pgrest_path]].join('/') if self[:pgrest_path].present?
    url
  end

  def self.pgrest_db_uri
    database_url(self[:pgrest_db_username], self[:pgrest_db_password])
  end

  def self.pgrest_nginx_upstream
    {
      pgrest_app: <<-UPSTREAM,
        server #{pgrest_server};
        keepalive 64;
      UPSTREAM
    }
  end

  def self.pgrest_nginx_location
    {
      "/#{self[:pgrest_path]}/" => <<-LOCATION,
        proxy_pass http://pgrest_app/;
  
        default_type application/json;
        proxy_hide_header Content-Location;
        add_header Content-Location /#{self[:pgrest_path]}/$upstream_http_content_location;
        proxy_set_header Connection "";
        proxy_http_version 1.1;
      LOCATION
    }
  end

  def self.database_url(user = self[:db_username], pwd = self[:db_password])
    "postgresql://#{user}:#{pwd}@#{self[:db_host] || '127.0.0.1'}:#{self[:db_port] || 5432}/#{self[:db_database]}"
  end

  def self.geoserver_private_server
    [self[:geoserver_private_host], self[:geoserver_private_port]].compact.join(':')
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
