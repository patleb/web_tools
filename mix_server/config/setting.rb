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
    url = "http#{'s' if self[:server_ssl]}://#{geoserver_server}"
    url = [url, self[:geoserver_path].presence || '/geoserver'].join
    url
  end

  def self.pgrest_local_url
    "http://#{pgrest_local_server}"
  end

  def self.pgrest_url
    url = "http#{'s' if self[:server_ssl]}://#{pgrest_server}"
    url = [url, self[:pgrest_path]].join if self[:pgrest_path].present?
    url
  end

  def self.pgrest_db_uri
    database_url(self[:pgrest_db_username], self[:pgrest_db_password])
  end

  def self.pgrest_nginx_upstream
    {
      pgrest_app: <<-UPSTREAM,
        server #{pgrest_local_server};
        keepalive 64;
      UPSTREAM
    }
  end

  def self.pgrest_nginx_location
    pgrest_timeout = Setting[:pgrest_timeout] / 1000
    {
      "#{self[:pgrest_path]}/" => <<-LOCATION,
        proxy_pass http://pgrest_app/;

        default_type application/json;
        proxy_hide_header Content-Location;
        add_header Content-Location #{self[:pgrest_path]}/$upstream_http_content_location;
        proxy_set_header Connection "";
        proxy_http_version 1.1;

        proxy_connect_timeout #{pgrest_timeout}s;
        proxy_send_timeout #{pgrest_timeout}s;
        proxy_read_timeout #{pgrest_timeout}s;
      LOCATION
    }
  end

  def self.geoserver_nginx_upstream
    {
      geoserver_app: <<-UPSTREAM,
        server #{geoserver_local_server};
      UPSTREAM
    }
  end

  def self.geoserver_nginx_location_wms
    {
      "#{self[:geoserver_path]}/wms" => <<-LOCATION,
        proxy_pass http://geoserver_app/geoserver/wms;
        proxy_redirect off;

        proxy_set_header Host $host;
        proxy_set_header X-Real-Ip $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 120s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
      LOCATION
    }
  end

  %i(geoserver_local geoserver pgrest_local pgrest).each do |name|
    define_singleton_method "#{name}_server" do
      [self["#{name}_host"], self["#{name}_port"]].compact.join(':')
    end
  end
end
