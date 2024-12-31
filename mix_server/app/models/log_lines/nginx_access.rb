### NOTE nginx has ms resolution
module LogLines
  class NginxAccess < LogLine
    REMOTE_ADDR     = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/
    REMOTE_USER     = /[-\w.]+/
    TIME_LOCAL      = %r{\d{1,2}/\w{3}/\d{4}(?::\d{2}){3} [+-]\d{4}}
    REQUEST         = /[^"]*/
    STATUS          = /\d{3}/
    BYTES_SENT      = /\d+/
    REQUEST_LENGTH  = /\d+/
    HTTP_REFERER    = /[^"]*/
    HTTP_USER_AGENT = /[^"]*/
    PIPE            = /[p.]/
    REQUEST_TIME    = /[-\d.]+/
    SCHEME          = /https?/
    GZIP_RATIO      = /[-\d.]+/
    PID             = /\d+/
    ACCESS = %r{
      (#{REMOTE_ADDR})\s-\s(#{REMOTE_USER})\s\[(#{TIME_LOCAL})\]\s
      "(#{REQUEST})"\s(#{STATUS})\s(#{BYTES_SENT})\s(#{REQUEST_LENGTH}\s)?
      "(#{HTTP_REFERER})"\s"(#{HTTP_USER_AGENT})"\s
      (#{REQUEST_TIME})(?:\s#{PIPE})?\s(#{REQUEST_TIME}\s)?-\s(#{SCHEME})\s-\s(#{GZIP_RATIO})(?:\s-\s(#{PID}))?
    }x
    ACCESS_LEVELS = {
      (100...400) => :info,
      404         => :warn, # not found
      406         => :warn, # not acceptable
      499         => :warn, # client disconnected
      (400...500) => :error,
      503         => :warn, # maintenance
      (500...600) => :fatal,
    }
    INVALID_URI = OpenStruct.new(path: nil)
    NULL_CHARS = ["\\u0000", "\0"]
    PERIODS = %i(year month week day hour)

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
      bytes_in: :big_integer,
      bytes_out: :big_integer,
      time: :float,
      referer: :string,
      browser: :json,
      gzip: :float,
    )

    scope :unique_users, -> { select(user).distinct.where_not(browser: nil) }
    scope :referers,     -> { where_not(referer: nil).where_not(referer: ['LIKE', '/%']) }
    scope :root,         -> { where(path: '/') }
    scope :rpc,          -> { where(path: ['~', "^#{MixRpc::Routes.root_path}/\\w+"]) }
    scope :pages,        -> { where(path: ['~', "^/[\\w-]+/#{MixPage::Routes::FRAGMENT}/"]) }
    scope :admin,        -> { where(path: ['~', "^#{MixAdmin::Routes.root_path}(/|$)"]) }
    scope :success,      -> { where(status: ['>=', 200]).where(status: ['<', 300]) }

    def self.user
      @user ||= "#{json_key(:ip)} || ' ' || #{json_key(:browser, cast: :text)}".sql_safe
    end

    def self.requests_begin_at
      success.order(:created_at).pick(:created_at)&.utc
    end

    def self.requests_end_at
      success.order(created_at: :desc).pick(:created_at)&.utc
    end

    def self.total_requests
      success.joins(:log_message).requests_by(:text_tiny)
    end

    def self.total_bytes_out
      success.sum(:bytes_out)
    end

    def self.total_bytes_in
      success.sum(:bytes_in)
    end

    def self.total_referers
      success.referers.requests_by(:referer)
    end

    def self.average_users(period = :week)
      from = success.unique_users.group_by_period(period)
      calculate_from(:average, from, :count, user).ceil
    end

    def self.average_bytes_out(period = :week)
      from = success.group_by_period(period).where_not(bytes_out: nil)
      calculate_from(:average, from, :sum, :bytes_out).ceil
    end

    def self.average_bytes_in(period = :week)
      from = success.group_by_period(period).where_not(bytes_in: nil)
      calculate_from(:average, from, :sum, :bytes_in).ceil
    end

    def self.average_time(period = :week)
      from = success.group_by_period(period).where_not(time: nil)
      calculate_from(:average, from, :average, :time).to_f.ceil(3)
    end

    def self.users_by(...)
      unique_users.requests_by(...)
    end

    def self.bytes_out_by(field, operation = :sum)
      requests_by(field, operation, :bytes_out)
    end

    def self.bytes_in_by(field, operation = :sum)
      requests_by(field, operation, :bytes_in)
    end

    def self.time_by(field, operation = :average)
      requests_by(field, operation, :time).transform_values{ |v| v.to_f.ceil(3) }
    end

    def self.requests_by(period_or_field, operation = :count, name = nil)
      case period_or_field
      when *PERIODS  then success.group_by_period(period_or_field, reverse: true).calculate(operation, name)
      when :browser  then success.top_group_calculate([:browser, UA[:name]], operation, column: name)
      when :platform then success.top_group_calculate([:browser, UA[:os_name]], operation, column: name)
      when :status   then top_group_calculate(period_or_field, operation, column: name)
      else                success.top_group_calculate(period_or_field, operation, column: name)
      end
    end

    def self.rollups!(log, *args, **options)
      return [] if log.path&.end_with?('/access.log')
      super
    end

    def self.rollups
      groups = %i(week day).each_with_object({}) do |period, result|
        result[[period, :period]] = success.group_by_period(period).calculate(LogRollups::NginxAccess::OPERATIONS)
        success.unique_users.group_by_period(period).count.each do |period_at, users|
          result[[period, :period]][period_at] << users
        end
      end
      groups[[:week, :path]] = success.group_by_period(:week).joins(:log_message).order_group(:text_tiny)
        .calculate(LogRollups::NginxAccess::OPERATIONS)
        .transform_keys!{ |(week, text_tiny)| [week, text_tiny.sub(/^2\d\d /, '')] }
      groups[[:week, :status]] = group_by_period(:week).order_group(:status).count
      groups[[:week, :referer]] = success.referers.group_by_period(:week).order_group(:referer).count
      [:country, :state, [:browser, UA[:name]], [:browser, UA[:os_name]]].each do |field|
        groups[[:week, field]] = success.where_not(field => nil).group_by_period(:week).order_group(field).count
      end
      hours = success.group_by_period(:hour).count
      (days = groups[[:day, :period]]).each do |day, row|
        row << 24.times.map{ |hour| hours[day + hour.hours] || 0 }
      end
      groups[[:week, :period]].each do |week, row|
        row << 24.times.map{ |hour| (0..7).sum{ |day| (days[week + day.days] || [[]]).last[hour] || 0 } }
      end
      groups.transform_values! do |group|
        group.transform_values! do |row|
          next row unless row.is_a? Array
          row.map!.with_index do |value, i|
            next value.ceil(3) if rollups_type(i) == :float
            value
          end
        end
      end
      groups.transform_keys! do |(period, group_name)|
        group_name = case group_name
          when [:browser, UA[:name]]    then :browser
          when [:browser, UA[:os_name]] then :platform
          else group_name
          end
        [period, group_name]
      end
    end

    # 142 MB unziped logs (226K rows) -->  167 MB (- 36 MB idx) in around 3 minutes
    #   without parameters            -->  122 MB (- 31 MB idx)
    #   without parameters + browser  -->  100 MB (- 28 MB idx)
    def self.parse(log, line, browser: true, parameters: true, **)
      return save_and_filter_unknown(line) unless (values = line.match(ACCESS))

      ip, user, created_at, request, status, bytes_out, bytes_in, referer, user_agent, upstream_time, time, https, gzip, pid = values.captures
      created_at = Time.strptime(created_at, '%d/%b/%Y:%H:%M:%S %z').utc
      method, path, protocol = request.split
      method = nil unless path
      method, path, protocol = nil, method, path unless protocol
      http = protocol&.split('/')&.last&.to_f
      uri, params = (Rack::Utils.parse_url(path) rescue [INVALID_URI, nil])
      params = nil if params&.any?{ |_, v| v = v.to_s; NULL_CHARS.any?{ |c| v.include? c } }
      path = uri.path&.downcase || ''
      path = path.delete_suffix('/') unless path == '/'
      referer_uri, _referer_params = (Rack::Utils.parse_url(referer) rescue [INVALID_URI, nil]) unless referer.blank? || referer == '-'
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
        path: path,
        params: (params&.except(*MixServer::Log.config.filter_parameters)&.reject{ |k, v| k.nil? && v.nil? } if parameters),
        status: (status = status.to_i),
        bytes_in: bytes_in&.to_i,
        bytes_out: bytes_out.to_i,
        time: time,
        referer: referer,
        browser: (_browsers(user_agent) if browser && user_agent.present? && user_agent != '-'),
        gzip: gzip == '-' ? nil : gzip.to_f,
      }
      global_log = log.path&.end_with?('/access.log')
      if global_log || status == 404 || MixServer::Log.config.filter_subnets.any?(&:include?.with(ip)) || path.end_with?(*MixServer::Log.config.filter_endings)
        method, path, params = nil, '*', nil
      end
      if global_log
        json_data.except! :method, :params, :referer, :browser
      end
      regex, replacement = MixServer::Log.config.ided_paths.find{ |regex, _replacement| path.match? regex }
      path_tiny = regex ? squish(path.gsub(regex, replacement)) : squish(path)
      if method
        params = (json_data[:params]&.pretty_hash! rescue '') || ''
        params_tiny = squish(params)
      end
      text_tiny = [status, method, path_tiny].join!(' ')
      level = global_log ? :info : ACCESS_LEVELS.select{ |statuses| statuses === status }.values.first
      message = {
        text_hash: [text_tiny, params_tiny].join!(' '),
        text_tiny: text_tiny,
        text: [status, method, path, params].join!(' '),
        level: level
      }
      { created_at: created_at, pid: pid&.to_i, message: message, json_data: json_data }
    rescue Exception => exception
      Log.rescue(exception, data: { line: line })
      { created_at: created_at, filtered: true }
    end

    def self.finalize(log)
      @_browsers = nil
    end

    def self._browsers(user_agent)
      (@_browsers ||= {})[user_agent] ||= begin
        ua = USER_AGENT_PARSER.parse(user_agent).browser_array
        ua.all?(&:nil?) ? [] : ua
      end
    end
  end
end
