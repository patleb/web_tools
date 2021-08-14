module LogLines
  class Auth < LogLine
    include WithRsyslog

    USER   = /[\w-]*/
    IP     = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/
    PORT   = /\d+/
    KEY    = /ssh.*/
    SIGNAL = /\d+/
    CLIENT_AUTH = /Accepted (?:publickey|password) for (#{USER}) from (#{IP}) port (#{PORT}) (#{KEY})/
    CLIENT_EXIT = /session closed for user (#{USER})/
    SERVER_AUTH = /Server listening on .* port (#{PORT})/
    SERVER_EXIT = /Received signal (#{SIGNAL}); terminating/

    json_attribute(
      user: :string,
      ip: :string,
      port: :integer,
      key: :string,
      signal: :integer,
    )

    def self.parse(log, line, mtime:, **)
      created_at, program, pid, text = rsyslog_parse(line, mtime)
      return { created_at: created_at, filtered: true } unless program == 'sshd'

      if (values = text.match(CLIENT_AUTH))
        user, ip, port, key = values.captures
        level = :info
        text_tiny = text.sub(/ #{KEY}$/, ' *')
      elsif (values = text.match(CLIENT_EXIT))
        user = values.captures.first
        level = :info
        text_tiny = text
      elsif (values = text.match(SERVER_AUTH))
        port = values.captures.first
        level = host(log)&.has_rebooted?(created_at) ? :warn : :error
        text_tiny = text.sub("::", '*')
      elsif (values = text.match(SERVER_EXIT))
        signal = values.captures.first
        level = host(log)&.has_rebooted?(created_at) ? :warn : :error
        text_tiny = text
      else
        return { created_at: created_at, filtered: true }
      end

      json_data = { user: user, ip: ip, port: port&.to_i, key: key, signal: signal&.to_i }
      message = { text: text, text_tiny: squish(text_tiny), level: level }

      { created_at: created_at, pid: pid, message: message, json_data: json_data }
    end
  end
end
