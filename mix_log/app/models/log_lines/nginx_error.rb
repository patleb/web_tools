module LogLines
  class NginxError < LogLine
    TIME          = %r{\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}}
    LEVEL         = /\w*/
    PROCESS_ID    = /\d+/
    THREAD_ID     = /\d+/
    CONNECTION_ID = /\d+/
    MESSAGE       = /.+/
    ERROR         = /(#{TIME}) \[(#{LEVEL})\] (#{PROCESS_ID})##{THREAD_ID}: (?:\*#{CONNECTION_ID} )?(#{MESSAGE})/
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
    }

    P_TIME         = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
    P_LEVEL        = /\w\d?/
    P_THREAD_ID    = /\w+/
    P_LOCATION     = %r{[\w/.:-]+}
    P_MESSAGE      = /[^:]+/
    P_NGINX        = %r{\[ (#{P_LEVEL}) (#{P_TIME})\.\d+ (#{PROCESS_ID})/T#{P_THREAD_ID} (#{P_LOCATION}) \]: (#{MESSAGE})}
    P_ERROR        = %r{(Error|App) (#{PROCESS_ID} )?(#{P_MESSAGE}): (#{MESSAGE})}
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

    IDED_TEXTS = [
      %r{(SSL_do_handshake\(\) failed \(SSL: error:)(\w+)},
      %r{(ID: )(\w+)},
      %r{(details saved to: /tmp/passenger-error-)(\w+)},
      %r{(Cannot checkout session because a spawning error occurred\. The identifier of the error is )(\w+)},
      %r{(/tmp/passenger_native_support-)(\w+)},
    ]

    json_attribute(
      level: :integer,
      pid: :integer,
    )
    enum level: ERROR_LEVELS.transform_values.with_index{ |_, i| i }

    def self.parse(log, line)
      if (values = line.match(ERROR))
        created_at, level, pid, text = values.captures
        created_at = Time.strptime("#{created_at} UTC", "%Y/%m/%d %H:%M:%S %z").utc
      elsif (values = line.match(P_NGINX))
        level, created_at, pid, location, text = values.captures
        level = P_ERROR_LEVELS[level]
        created_at = Time.strptime("#{created_at} UTC", "%Y-%m-%d %H:%M:%S %z").utc
        text = "#{location}: #{text}"
      elsif (values = line.match(P_ERROR))
        level, pid, p_message, text = values.captures
        level = P_ERROR_LEVELS[level]
        text = "#{p_message}: #{text}"
      else
        raise IncompatibleLogLine
      end
      if (regex = IDED_TEXTS.find{ |regex| text.match? regex })
        text_tiny = squish(text.sub(regex, '\1*'))
      else
        text_tiny = squish(text)
      end
      label = { text_tiny: text_tiny, text: text, level: ERROR_LEVELS[level] }
      json_data = { level: levels[level], pid: pid&.to_i }.compact

      { created_at: created_at, label: label, json_data: json_data }
    end
  end
end
