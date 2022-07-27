Setting.class_eval do
  def self.ftp_host_path
    "/#{rails_app}/#{rails_env}"
  end

  def self.geoserver_local_url
    "http://#{geoserver_local_server}/geoserver"
  end

  def self.geoserver_url
    url = "http#{'s' if self[:server_ssl]}://#{geoserver_server}"
    url = [url, self[:geoserver_path].presence || '/geoserver'].join
    url
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

  %i(geoserver_local geoserver).each do |name|
    define_singleton_method "#{name}_server" do
      [self["#{name}_host"], self["#{name}_port"]].compact.join(':')
    end
  end
end
