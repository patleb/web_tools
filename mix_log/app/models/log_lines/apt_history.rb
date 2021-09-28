module LogLines
  class AptHistory < LogLine
    START_DATE = /^Start-Date: (\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/
    END_DATE   = /^End-Date: \d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}/
    COMMAND    = /^Commandline: (.+)$/
    INFO       = /^(?:[\w-]+): (?:.+)$/
    INSTALL    = /^(apt-get -y install) (.+)$/

    json_attribute(
      command: :string,
    )

    scope :unattended_upgrade, -> { where(command: '/usr/bin/unattended-upgrade') }

    def self.was_upgraded?(time)
      unattended_upgrade.where(created_at: (time - 5.minutes)..time).exists?
    end

    def self.parse(log, line, previous:, **)
      if (values = line.match(START_DATE))
        created_at = Time.parse("#{values.captures.first} UTC")
        message = { text: "look in apt/history.log", level: :info }
      elsif (values = line.match(COMMAND))
        anchored = true
        created_at = previous[:created_at]
        command = values.captures.first
        message = { text: command, level: :info }
      elsif (end_date = line.match?(END_DATE)) || line.match?(INFO)
        anchored = true
        created_at = previous[:created_at]
        command = previous.dig(:json_data, :command)
        text = previous.dig(:message, :text)
        text_tiny = text.sub(INSTALL, '\1 *') if end_date && text.match?(INSTALL)
        message = { text: text, text_tiny: text_tiny, level: :info }
      else
        return { filtered: true }
      end
      json_data = { command: command }

      { created_at: created_at, message: message, json_data: json_data, anchored: anchored }
    end
  end
end
