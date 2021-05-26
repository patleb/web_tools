module LogLines
  class JobWatchAction < LogLine
    json_attribute(
      action: :string,
      time: :float,
      ram: :big_integer,
    )

    def self.push(log, action, time)
      json_data = { action: action, time: time, ram: Process.worker.ram_used }
      message = { text: action, level: :info }
      super(log, message: message, json_data: json_data)
    end
  end
end
