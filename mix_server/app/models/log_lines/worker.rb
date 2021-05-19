module LogLines
  class Worker < LogLine
    json_attribute(
      command: :string,
      stopped: :boolean,
      ram: :integer,
    )

    def self.push(log, stop: nil)
      json_data = { command: Process.worker.cmdline, stopped: stop, ram: Process.worker.ram_used }
      message = { text: json_data[:command], level: :info }
      super(log, message: message, json_data: json_data)
    end
  end
end
