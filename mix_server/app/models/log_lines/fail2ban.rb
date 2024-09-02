# frozen_string_literal: true

module LogLines
  class Fail2ban < LogLine
    TIME     = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/
    PID      = /\d+/
    LEVEL    = /\w+/
    PROGRAM  = /\w+/
    MESSAGE  = /.+/
    FAIL2BAN = /(#{TIME}),\d+ fail2ban\.\w+ +\[(#{PID})\]: (#{LEVEL}) +(?:\[(#{PROGRAM})\] )?(#{MESSAGE})/
    FAIL2BAN_LEVELS = {
      'CRITICAL' => :fatal,
      'ERROR'    => :error,
      'WARNING'  => :warn,
      'NOTICE'   => :warn,
      'INFO'     => :info,
      'DEBUG'    => :debug,
    }
    FILTERED_LEVELS = %w(INFO DEBUG)
    FAIL2BAN_IP     = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/

    json_attribute :ip

    def self.parse(log, line, **)
      return save_and_filter_unknown(line) unless (values = line.match(FAIL2BAN))

      created_at, pid, level, program, text = values.captures
      created_at = Time.strptime("#{created_at} UTC", '%Y-%m-%d %H:%M:%S %z').utc
      return { created_at: created_at, filtered: true } unless program == 'sshd' && FILTERED_LEVELS.exclude?(level)

      json_data = { ip: text[FAIL2BAN_IP] }
      message = { text: text, level: FAIL2BAN_LEVELS[level] }

      { created_at: created_at, pid: pid.to_i, message: message, json_data: json_data }
    end
  end
end
