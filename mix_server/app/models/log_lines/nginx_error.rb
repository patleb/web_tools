module LogLines
  class NginxError < LogLine
    TIME          = %r{\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}}
    LEVEL         = /\w*/
    PID           = /\d+/
    THREAD_ID     = /\d+/
    CONNECTION_ID = /\d+/
    MESSAGE       = /.+/
    ERROR         = /(#{TIME}) \[(#{LEVEL})\] (#{PID})##{THREAD_ID}: (?:\*#{CONNECTION_ID} )?(#{MESSAGE})/
    ERROR_LEVELS  = {
      'debug'  => :debug,
      'info'   => :info,
      'notice' => :info,
      'warn'   => :warn,
      'error'  => :error,
      'crit'   => :error,
      'alert'  => :fatal,
      'emerg'  => :fatal,
      'ruby'   => :unknown,
    }.to_hwka

    P_TIME         = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
    P_LEVEL        = /\w\d?/
    P_THREAD_ID    = /\w+/
    P_LOCATION     = %r{[\w/.:-]+}
    P_MESSAGE      = /[^:]+/
    P_NGINX        = %r{\[ (#{P_LEVEL}) (#{P_TIME})\.\d+ (#{PID})/T#{P_THREAD_ID} (#{P_LOCATION}) \]: (#{MESSAGE})}
    P_ERROR        = %r{(Error|App) (#{PID} )?(#{P_MESSAGE}): (#{MESSAGE})}
    P_ERROR_LEVELS = {
      'D3'    => 'debug',
      'D2'    => 'debug',
      'D'     => 'debug',
      'I'     => 'info',
      'N'     => 'notice',
      'W'     => 'warn',
      'E'     => 'error',
      'Error' => 'error',
      'C'     => 'crit',
      'App'   => 'ruby',
    }
    SYSTEM_ERROR = %i(error fatal unknown)

    def self.parse(log, line, mtime:, **)
      if (values = line.match(ERROR))
        created_at, level, pid, text = values.captures
        created_at = Time.strptime("#{created_at} UTC", '%Y/%m/%d %H:%M:%S %z').utc
      elsif (values = line.match(P_NGINX))
        level, created_at, pid, location, text = values.captures
        level = P_ERROR_LEVELS[level]
        created_at = Time.strptime("#{created_at} UTC", '%Y-%m-%d %H:%M:%S %z').utc
        text = "#{location}: #{text}"
      elsif (values = line.match(P_ERROR))
        level, pid, p_message, text = values.captures
        level = P_ERROR_LEVELS[level]
        created_at = mtime
        text = "#{p_message}: #{text}"
      else
        return { filtered: true }
      end
      text = "#{location || p_message || 'invalid'}: �" if unprintable? text
      text_tiny = text.dup
      MixServer::Logs.config.ided_errors.each do |regex, replacement|
        text_tiny.gsub! regex, replacement
      end
      text_tiny = squish(text_tiny)
      known_level, _ = MixServer::Logs.config.known_errors.find do |_level, errors|
        errors.find{ |e| e.is_a?(Regexp) ? text.match?(e) : text.include?(e) }
      end
      level = known_level || level
      level = ERROR_LEVELS[level]
      return { filtered: true } unless SYSTEM_ERROR.include? level
      return { filtered: true } if text_tiny.start_with?('output: ') && text_tiny.size < 36 # filter invalid/short lines

      message = { text_tiny: text_tiny, text: text, level: level }

      { created_at: created_at, pid: pid&.to_i, message: message }
    end
  end
end
