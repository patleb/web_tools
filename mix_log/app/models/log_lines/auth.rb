module LogLines
  class Auth < LogLine
    include WithRsyslog

    USER = /[\w-]*/
    IP   = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/
    PORT = /\d+/
    KEY  = /ssh.+/
    CLIENT_AUTH  = /(?:Accepted publickey|session (?:opened|closed)) for (?:user )?(#{USER})(?: from (#{IP}) port (#{PORT}) (#{KEY}))?/
    CLIENT_EXIT  = /(?:Received disconnect from|Disconnected from user (#{USER})) (#{IP}) port (#{PORT})(?:$|:\d+: disconnected by user$)/
    SERVER_AUTH  = /Server listening on .* port (#{PORT})/
    INVALID_AUTH = /(?:user (#{USER}) )?(?:from )?(#{IP}) port (#{PORT})/i

    json_attribute(
      ip: :string,
      port: :integer,
      user: :string,
      key: :string,
    )

    def self.parse(log, line, mtime:, **)
      created_at, program, pid, text = rsyslog_parse(line, mtime)
      return { created_at: created_at, filtered: true } unless program == 'sshd'

      if (values = text.match(CLIENT_AUTH))
        user, ip, port, key = values.captures
        level = :info
        text_tiny = text.sub("user #{user}", 'user *').sub(/ #{KEY}$/, ' *')
      elsif (values = text.match(CLIENT_EXIT))
        user, ip, port = values.captures
        level = :info
        text_tiny = text
      elsif (values = text.match(SERVER_AUTH))
        port = values.captures.first
        level = :error # server restart
        text_tiny = text.sub("::", '*')
      elsif (values = text.match(INVALID_AUTH))
        user, ip, port = values.captures
        level = :warn
        text_tiny = user ? text.sub("user #{user}", 'user *') : text
      else
        raise IncompatibleLogLine
      end

      json_data = { user: user, ip: ip, port: port&.to_i, key: key }
      message = { text: text, text_tiny: squish(text_tiny), level: level }

      { created_at: created_at, pid: pid, message: message, json_data: json_data }
    end
  end
end
