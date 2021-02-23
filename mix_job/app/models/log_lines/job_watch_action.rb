module LogLines
  class JobWatchAction < LogLine
    json_attribute(
      action: :string,
      time: :float,
    )

    def self.push(log, action, time)
      json_data = { action: action, time: time }
      label = { text: action, level: :info }
      super(log, pid: Process.pid, label: label, json_data: json_data)
    end
  end
end
