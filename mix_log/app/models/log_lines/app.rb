module LogLines
  class App < LogLine
    TIME    = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+/
    PID     = /\d+/
    UUID    = /[\w-]+/
    FATAL   = /^F, \[(#{TIME}) #(#{PID})\] FATAL -- : \[(#{UUID})\]/
    MESSAGE = /^\[(#{UUID})\] (.+)$/

    json_attribute(
      uuid: :string,
    )

    def self.parse(log, line, previous:, **)
      if (values = line.match(FATAL))
        created_at, pid, uuid = values.captures
        created_at, pid = Time.parse("#{created_at} UTC"), pid.to_i
        message = { text: 'look in rails log', level: :fatal } # wasn't able to anchor the next line
      elsif (values = line.match(MESSAGE))
        uuid, text = values.captures
        return { filtered: true } if previous&.dig(:filtered) || uuid != previous&.dig(:json_data, :uuid)
        anchored = true
        created_at, pid = previous.values_at(:created_at, :pid)
        message = { text: text, level: :fatal }
      else
        return { filtered: true }
      end
      json_data = { uuid: uuid }

      { created_at: created_at, pid: pid, message: message, json_data: json_data, anchored: anchored }
    end
  end
end
