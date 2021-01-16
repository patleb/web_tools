module LogLines
  class Syslog < LogLine
    TIME    = /[A-Z][a-z]{2}\s+\d+ \d{2}:\d{2}:\d{2}/
    HOST    = /[\w-]+/
    PROGRAM = /[\w.-]+/
    PID     = /\d+/
    MESSAGE = /.+/
    SYSLOG  = /(#{TIME}) #{HOST} (#{PROGRAM})\[(#{PID})\]: (#{MESSAGE})/

    USER = /\w+/
    CMD  = /.+/
    CRON = /\((#{USER})\) CMD \((#{CMD})\)$/

    def self.parse(log, line, mtime:)
      raise IncompatibleLogLine unless (values = line.match(SYSLOG))

      created_at, program, pid, message = values.captures
      created_at = Time.strptime("#{mtime.year} #{created_at} UTC", "%Y %b %e %H:%M:%S %z").utc
      created_at = created_at.change(year: mtime.year - 1) if created_at.month == 12 && mtime.month < 12
      return { created_at: created_at, filtered: true } unless program == 'CRON'

      raise IncompatibleLogLine unless (values = message.match(CRON))

      user, command = values.captures
      json_data = { user: user, pid: pid.to_i }
      label = { text: command.strip, level: :info }

      { created_at: created_at, label: label, json_data: json_data }
    end
  end
end
