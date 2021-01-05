module LogLines
  class NginxAccess < LogLine
    REMOTE_ADDR     = /\d{1,3}(?:\.\d{1,3}){3}/
    REMOTE_USER     = /[-\w]+/
    TIME_LOCAL      = %r{\d{1,2}/\w{3}/\d{4}(?::\d{2}){3} [+-]\d{4}}
    REQUEST         = /[^"]*/
    STATUS          = /\d{3}/
    BODY_BYTES_SENT = /\d+/
    HTTP_REFERER    = /[^"]+/
    HTTP_USER_AGENT = /[^"]+/
    PIPE            = /[p.]/
    REQUEST_TIME    = /[-\d.]+/
    SCHEME          = /https?/
    GZIP_RATIO      = /[-\d.]+/
    ACCESS = %r{
      (#{REMOTE_ADDR})\s-\s(#{REMOTE_USER})\s\[(#{TIME_LOCAL})\]\s
      "(#{REQUEST})"\s(#{STATUS})\s(#{BODY_BYTES_SENT})\s
      "(#{HTTP_REFERER})"\s"(#{HTTP_USER_AGENT})"\s
      (#{REQUEST_TIME})\s(#{PIPE})\s(#{REQUEST_TIME}\s)?-\s(#{SCHEME})\s-\s(#{GZIP_RATIO})
    }x

    INVALID_URI = OpenStruct.new(path: nil)

    json_attribute(
      ip: :string,
      country: :string,
      state: :string,
      user: :string,
      http: :float,
      ssl: :boolean,
      method: :string,
      path: :string,
      params: :json,
      status: :integer,
      bytes: :integer,
      time: :float,
      referer: :string,
      browser: :json,
      pipe: :boolean,
      gzip: :float,
    )

    def self.push_all(log_id, lines)
      ips = lines.map{ |line| line.dig(:json_data, :ip) }
      GeoIp.select_by_ips(ips).pluck('country_code', 'state_code').each_with_index do |(country, state), i|
        lines[i][:json_data][:country] = country
        lines[i][:json_data][:state] = state if state
      end
      super
    end

    # 142 MB unziped logs (226K rows) -->  167 MB (- 36 MB idx) in 3 minutes
    #   without parameters            -->  122 MB (- 31 MB idx)
    #   without parameters + browser  -->  100 MB (- 28 MB idx)
    def self.parse(line, geo_ip: false, browser: true, parameters: true)
      raise IncompatibleLogLine unless (values = line.match(ACCESS))

      ip, user, created_at, request, status, bytes, referer, user_agent, upstream_time, pipe, time, https, gzip = values.captures
      geo_ip = geo_ip ? GeoIp.find_by_ip(ip) : nil
      created_at = Time.strptime(created_at, "%d/%b/%Y:%H:%M:%S %z").utc
      method, path, protocol = request.split(' ')
      method = nil unless path
      method, path, protocol = nil, method, path unless protocol
      http = protocol&.split('/')&.last&.to_f
      uri, params = (Rack::Utils.parse_url(path) rescue [INVALID_URI, nil])
      referer_uri, _referer_params = (Rack::Utils.parse_url(referer) rescue [INVALID_URI, nil]) unless referer == '-'
      referer_host = referer_uri&.hostname
      referer = [(referer_host if referer_host != Setting[:server_host]), referer_uri&.path].compact.join
      time = time.in?([nil, '-']) ? nil : time.to_f
      time ||= upstream_time == '-' ? nil : upstream_time.to_f
      json_data = {
        ip: ip,
        country: geo_ip&.country_code,
        state: geo_ip&.state_code,
        user: user == '-' ? nil : user,
        http: http == 0.0 ? nil : http,
        ssl: https == 'https',
        method: method,
        path: uri.path,
        params: (params&.except(*MixLog.config.filter_parameters) if parameters),
        status: status.to_i,
        bytes: bytes.to_i,
        time: time,
        referer: referer,
        browser: (_browsers(user_agent) if browser),
        pipe: pipe == 'p', # called from localhost with http-rb and keep-alive
        gzip: gzip == '-' ? nil : gzip.to_f,
      }.reject{ |_, v| v.blank? }
      hash_id = json_data.values_at(:method, :path, :params)
      hash_id[-1] = hash_id.last&.sort_by(&:first)
      hash_id = hash_id.join(' ').squish_numbers.squish!.presence
      hash_id = Digest.md5_hex(hash_id) if hash_id

      { created_at: created_at, hash_id: hash_id, json_data: json_data }
    end

    def self.finalize
      @_browsers = nil
    end

    def self._browsers(user_agent)
      (@_browsers ||= {})[user_agent] ||= USER_AGENT_PARSER.parse(user_agent).browser
    end
  end
end
