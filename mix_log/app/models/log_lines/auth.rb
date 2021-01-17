module LogLines
  class Auth < LogLine
    include Rsyslog

    USER = /[\w-]*/
    IP   = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/
    PORT = /\d+/
    KEY  = /ssh.+/
    CLIENT_AUTH  = /(?:Accepted publickey|session (?:opened|closed)) for (?:user )?(#{USER})(?: from (#{IP}) port (#{PORT}) (#{KEY}))?/
    CLIENT_EXIT  = /(?:Received disconnect from|Disconnected from user (#{USER})) (#{IP}) port (#{PORT})(?:$|:\d+: disconnected by user$)/
    SERVER_AUTH  = /Server listening on .* port (#{PORT})/
    INVALID_AUTH = /(?:user (#{USER}) )?(?:from )?(#{IP}) port (#{PORT})/i

    def self.parse(log, line, mtime:)
      created_at, program, pid, message = rsyslog_parse(line, mtime)
      return { created_at: created_at, filtered: true } unless program == 'sshd'

      if (values = message.match(CLIENT_AUTH))
        user, ip, port, key = values.captures
        level = :info
        text_tiny = message.sub("user #{user}", 'user *').sub(/ #{KEY}$/, ' *')
      elsif (values = message.match(CLIENT_EXIT))
        user, ip, port = values.captures
        level = :info
        text_tiny = message
      elsif (values = message.match(SERVER_AUTH))
        port = values.captures.first
        level = :error
        text_tiny = message.sub("::", '*')
      elsif (values = message.match(INVALID_AUTH))
        user, ip, port = values.captures
        level = :warn
        text_tiny = user ? message.sub("user #{user}", 'user *') : message
      else
        raise IncompatibleLogLine
      end

      json_data = { user: user, pid: pid, ip: ip, port: port&.to_i, key: key }
      label = { text: message, text_tiny: squish(text_tiny), level: level }

      { created_at: created_at, label: label, json_data: json_data }
    end
  end
end
