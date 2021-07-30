module LogLines
  module WithRsyslog
    extend ActiveSupport::Concern

    TIME    = /[A-Z][a-z]{2}\s+\d+ \d{2}:\d{2}:\d{2}/
    HOST    = /[\w-]+/
    PROGRAM = /[^\[:]+/
    PID     = /\d+/
    MESSAGE = /.+/
    RSYSLOG  = /(#{TIME}) #{HOST} (#{PROGRAM})(?:\[(#{PID})\])?: (#{MESSAGE})/

    class_methods do
      def rsyslog_parse(line, mtime)
        raise LogLine::IncompatibleLogLine, line unless (values = line.match(RSYSLOG))

        created_at, program, pid, message = values.captures
        created_at = Time.strptime("#{mtime.year} #{created_at} UTC", "%Y %b %e %H:%M:%S %z").utc
        created_at = created_at.change(year: mtime.year - 1) if created_at.month == 12 && mtime.month < 12
        [created_at, program, pid&.to_i, message]
      end
    end
  end
end
