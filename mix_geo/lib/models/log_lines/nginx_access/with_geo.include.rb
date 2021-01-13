module LogLines::NginxAccess::WithGeo
  extend ActiveSupport::Concern

  class_methods do
    def push_all(log, lines)
      ips = lines.map{ |line| line.dig(:json_data, :ip) }
      GeoIp.select_by_ips(ips).pluck('country_code', 'state_code').each_with_index do |(country, state), i|
        lines[i][:json_data][:country] = country
        lines[i][:json_data][:state] = state if state
      end
      super
    end
  end
end
