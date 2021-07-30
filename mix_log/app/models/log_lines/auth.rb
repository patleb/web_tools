module LogLines
  class Auth < LogLine
    include WithRsyslog

    USER = /[\w-]*/
    IP   = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/
    PORT = /\d+/
    KEY  = /ssh.*/
    CLIENT_AUTH = /Accepted (?:publickey|password) for (#{USER}) from (#{IP}) port (#{PORT}) (#{KEY})/
    CLIENT_EXIT = /session closed for user (#{USER})/
    SERVER_AUTH = /Server listening on .* port (#{PORT})/
    SERVER_EXIT = /Received signal \d+; terminating/

    json_attribute(
      user: :string,
      ip: :string,
      port: :integer,
      key: :string,
    )

    def self.parse(log, line, mtime:, **)
      created_at, program, pid, text = rsyslog_parse(line, mtime)
      return { created_at: created_at, filtered: true } unless program == 'sshd'

      if (values = text.match(CLIENT_AUTH))
        user, ip, port, key = values.captures
        level = :info
        text_tiny = text.sub(/ #{KEY}$/, ' *')
      elsif (values = text.match(CLIENT_EXIT))
        user = values.captures
        level = :info
        text_tiny = text
      elsif (values = text.match(SERVER_AUTH))
        port = values.captures.first
        level = :error # server start
        text_tiny = text.sub("::", '*')
      elsif text.match?(SERVER_EXIT)
        level = :error # server stop
      else
        return { created_at: created_at, filtered: true }
      end

      json_data = { user: user, ip: ip, port: port&.to_i, key: key }
      message = { text: text, text_tiny: squish(text_tiny), level: level }

      { created_at: created_at, pid: pid, message: message, json_data: json_data }
    end
  end
end
