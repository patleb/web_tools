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
    ACCESS_LEVELS = {
      (100...400) => :info,
      404         => :warn, # not found
      406         => :warn, # not acceptable
      499         => :warn, # client disconnected
      (400...500) => :error,
      (500...600) => :fatal,
    }

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

    # 142 MB unziped logs (226K rows) -->  167 MB (- 36 MB idx) in around 3 minutes
    #   without parameters            -->  122 MB (- 31 MB idx)
    #   without parameters + browser  -->  100 MB (- 28 MB idx)
    def self.parse(log, line, browser: true, parameters: true)
      raise IncompatibleLogLine unless (values = line.match(ACCESS))

      ip, user, created_at, request, status, bytes, referer, user_agent, upstream_time, pipe, time, https, gzip = values.captures
      created_at = Time.strptime(created_at, "%d/%b/%Y:%H:%M:%S %z").utc
      status, bytes = status.to_i, bytes.to_i
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
        user: user == '-' ? nil : user,
        http: http == 0.0 ? nil : http,
        ssl: https == 'https',
        method: method,
        path: uri.path,
        params: (params&.except(*MixLog.config.filter_parameters)&.reject{ |k, v| k.nil? && v.nil? } if parameters),
        status: status,
        bytes: bytes,
        time: time,
        referer: referer,
        browser: (_browsers(user_agent) if browser),
        pipe: pipe == 'p', # called from localhost with http-rb and keep-alive
        gzip: gzip == '-' ? nil : gzip.to_f,
      }.reject{ |_, v| v.blank? }
      global_log = log.path&.end_with?('/access.log')
      path = json_data[:path]&.downcase || ''
      path = path.delete_suffix('/') unless path == '/'
      if global_log || status == 404 || path.end_with?('/wp-admin', '/allowurl.txt', '.php')
        method, path, params = nil, '*', nil
      end
      regex, replacement = MixLog.config.ided_paths.find{ |regex, _replacement| path.match? regex }
      if regex
        path_tiny = squish(path.gsub(regex, replacement))
      else
        path_tiny = squish(path)
      end
      if method
        pjax = json_data[:params]&.any?{ |k, _| k.start_with? '_pjax' } ? 'pjax' : nil
        params = json_data[:params]&.pretty_hash || ''
        params_tiny = squish(params)
      end
      level = global_log ? :info : ACCESS_LEVELS.select{ |statuses| statuses === status }.values.first
      label = {
        text_hash: [status, method, path_tiny, params_tiny].present_join(' '),
        text_tiny: [status, method, path_tiny, pjax].present_join(' '),
        text: [status, method, path, params].present_join(' '),
        level: level
      }

      { created_at: created_at, label: label, json_data: json_data }
    end

    def self.finalize
      @_browsers = nil
    end

    def self._browsers(user_agent)
      (@_browsers ||= {})[user_agent] ||= USER_AGENT_PARSER.parse(user_agent).browser
    end
  end
end
