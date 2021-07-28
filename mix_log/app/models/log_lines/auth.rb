module LogLines
  class Auth < LogLine
    include WithRsyslog

    USER = /[\w-]*/
    IP   = /(?:[0-9]{1,3}\.){3}[0-9]{1,3}/
    PORT = /\d+/
    KEY  = /ssh.+/
    CLIENT_AUTH    = /(?:Accepted publickey|session (?:opened|closed)) for (?:user )?(#{USER})(?: from (#{IP}) port (#{PORT}) (#{KEY}))?/
    CLIENT_EXIT    = /(?:Received disconnect from|Disconnected from user (#{USER})) (#{IP}) port (#{PORT})(?:$|:\d+: disconnected by user$)/
    SERVER_AUTH    = /Server listening on .* port (#{PORT})/
    SERVER_EXIT    = /Received signal \d+; terminating/
    INVALID_AUTH   = /(?:user (#{USER}) )?(?:from )?(#{IP}) port (#{PORT})/i
    PWD_INVALID    = /pam.+failures?; .+ rhost=(#{IP})(?:\s+user=(#{USER}))?/i
    BAD_KEY_METHOD = /Unable to negotiate with (#{IP}) port (#{PORT}): no matching key exchange method found/
    BAD_KEY_EXIT   = 'error: kex_exchange_identification: Connection closed by remote host'
    BAD_KEY_USER   = 'pam_unix(sshd:auth): check pass; user unknown'

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
        level = :error # server start
        text_tiny = text.sub("::", '*')
      elsif text.match?(SERVER_EXIT)
        level = :error # server stop
      elsif (values = text.match(INVALID_AUTH))
        user, ip, port = values.captures
        level = :warn
        text_tiny = user ? text.sub("user #{user}", 'user *') : text
      elsif (values = text.match(PWD_INVALID))
        ip, user = values.captures
        level = :warn
        text_tiny = user ? text.sub("user=#{user}", 'user=*') : text
      elsif (values = text.match(BAD_KEY_METHOD))
        ip, port = values.captures
        level = :warn
        text_tiny = text.sub(/Their offer: .+/, 'Their offer: *')
      elsif text.include?(BAD_KEY_EXIT) || text.include?(BAD_KEY_USER)
        return { filtered: true }
      else
        raise IncompatibleLogLine, line
      end

      json_data = { user: user, ip: ip, port: port&.to_i, key: key }
      message = { text: text, text_tiny: squish(text_tiny), level: level }

      { created_at: created_at, pid: pid, message: message, json_data: json_data }
    end
  end
end
