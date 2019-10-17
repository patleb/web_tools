Setting.class_eval do
  def self.ftp_host_path
    if defined? Rails
      "/#{Rails.application.name}/#{Rails.env}"
    else
      "/#{rails_app}/#{rails_env}"
    end
  end

  def self.geoserver_local_url
    "http://#{geoserver_local_server}/geoserver"
  end

  def self.geoserver_url
    ["http://#{geoserver_server}", self[:geoserver_path].presence || 'geoserver'].join('/')
  end

  def self.pgrest_local_url
    "http://#{pgrest_local_server}"
  end

  def self.pgrest_url
    url = "http#{'s' if self[:pgrest_ssl]}://#{pgrest_server}"
    url = [url, self[:pgrest_path]].join('/') if self[:pgrest_path].present?
    url
  end

  def self.pgrest_db_uri
    database_url(self[:pgrest_db_username], self[:pgrest_db_password])
  end

  # TODO move to settings.yml --> https://stackoverflow.com/questions/3790454/how-do-i-break-a-string-over-multiple-lines
  def self.pgrest_nginx_upstream
    {
      pgrest_app: <<-UPSTREAM,
        server #{pgrest_local_server};
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

  %i(geoserver_local geoserver pgrest_local pgrest).each do |name|
    define_singleton_method "#{name}_server" do
      [self["#{name}_host"], self["#{name}_port"]].compact.join(':')
    end
  end

  def self.server
    [self[:server_host], self[:server_port]].compact.join(':')
  end
end
