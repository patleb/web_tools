module LogLines
  class NginxError < LogLine
    TIME          = %r{\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}}
    LEVEL         = /\w*/
    PROCESS_ID    = /\d+/
    THREAD_ID     = /\d+/
    CONNECTION_ID = /\d+/
    MESSAGE       = /.+/
    ERROR         = /(#{TIME}) \[(#{LEVEL})\] (#{PROCESS_ID})##{THREAD_ID}: (?:\*#{CONNECTION_ID} )?(#{MESSAGE})/

    P_TIME          = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
    P_LEVEL         = /\w{1,2}/
    P_THREAD_ID     = /\w+/
    P_LOCATION      = %r{[\w/.:-]+}
    P_MESSAGE       = /[^:]+/
    PASSENGER_NGINX = %r{\[ (#{P_LEVEL}) (#{P_TIME})\.\d+ (#{PROCESS_ID})/T#{P_THREAD_ID} (#{P_LOCATION}) \]: (#{MESSAGE})}
    PASSENGER_ERROR = %r{(#{P_LEVEL}|Error|App) (#{PROCESS_ID} )?(#{P_MESSAGE}): (#{MESSAGE})}

    LEVELS = %w(
      ruby
      emerg
      alert
      crit
      error
      warn
      notice
      info
      debug
    ).each_with_object({}).with_index{ |(level, result), i| result[level] = i }

    P_LEVELS = {
      'App' => 'ruby',
      'C' => 'crit',
      'Error' => 'error',
      'E' => 'error',
      'W' => 'warn',
      'N' => 'notice',
      'I' => 'info',
      'D' => 'debug',
      'D2' => 'debug',
      'D3' => 'debug',
    }

    json_attribute(
      level: :integer,
      pid: :integer,
    )
    enum level: LEVELS

    def self.parse(line, **)
      if (values = line.match(ERROR))
        created_at, level, pid, message = values.captures
        created_at = Time.strptime("#{created_at} UTC", "%Y/%m/%d %H:%M:%S %z").utc
      elsif (values = line.match(PASSENGER_NGINX))
        level, created_at, pid, location, message = values.captures
        level = P_LEVELS[level]
        created_at = Time.strptime("#{created_at} UTC", "%Y-%m-%d %H:%M:%S %z").utc
        message = "#{location}: #{message}"
      elsif (values = line.match(PASSENGER_ERROR))
        level, pid, p_message, message = values.captures
        level = P_LEVELS[level]
        message = "#{p_message}: #{message}"
      else
        raise IncompatibleLogLine
      end
      message_hash = Digest.md5_hex(message.squish_numbers.squish!)
      json_data = {
        level: LEVELS[level],
        pid: pid&.to_i,
      }.compact

      { message: message, message_hash: message_hash, created_at: created_at, json_data: json_data }
    end
  end
end
