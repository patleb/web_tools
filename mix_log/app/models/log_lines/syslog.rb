module LogLines
  class Syslog < LogLine
    include WithRsyslog

    USER = /\w+/
    CMD  = /.+/
    CRON = /\((#{USER})\) CMD \((#{CMD})\)$/

    json_attribute :user

    def self.parse(log, line, mtime:, **)
      created_at, program, pid, message = rsyslog_parse(line, mtime)
      return { created_at: created_at, filtered: true } unless program == 'CRON'

      raise IncompatibleLogLine unless (values = message.match(CRON))

      user, text = values.captures
      json_data = { user: user }
      message = { text: text.strip, level: :info }

      { created_at: created_at, pid: pid, message: message, json_data: json_data }
    end
  end
end
