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
        { id: '127.0.0.0',   country_code: 'XV', coordinates: [0.0, 0.0] },
        { id: '10.0.0.0',    country_code: 'XA', coordinates: [0.0, 0.0] },
        { id: '172.16.0.0',  country_code: 'XB', coordinates: [0.0, 0.0] },
        { id: '192.168.0.0', country_code: 'XC', coordinates: [0.0, 0.0] },
      ]
    end
  end
end
