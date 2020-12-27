module MixGeo
  has_config do
    attr_writer :supported_countries
    attr_writer :extra_countries
    attr_writer :extra_ips

    def supported_countries
      @supported_countries ||= ['US', 'CA']
    end

    def extra_countries
      @extra_countries ||= [
        { id: 916, code: 'XA', name: 'Host' },
        { id: 917, code: 'XB', name: 'Private Network' },
        { id: 926, code: 'XK', name: 'Kosovo' },
      ]
    end

    def extra_ips
      @extra_ips ||= [
        { ip_first: '127.0.0.0',   ip_last: '127.255.255.255', country_code: 'XA', geo_country_id: 916, latitude: 0.0, longitude: 0.0 },
        { ip_first: '10.0.0.0',    ip_last: '10.255.255.255',  country_code: 'XB', geo_country_id: 917, latitude: 0.0, longitude: 0.0 },
        { ip_first: '172.16.0.0',  ip_last: '172.31.255.255',  country_code: 'XB', geo_country_id: 917, latitude: 0.0, longitude: 0.0 },
        { ip_first: '192.168.0.0', ip_last: '192.168.255.255', country_code: 'XB', geo_country_id: 917, latitude: 0.0, longitude: 0.0 },
      ]
    end
  end
end
