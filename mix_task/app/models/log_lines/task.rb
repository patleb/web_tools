module LogLines
  class Task < LogLine
    json_attribute(
      name: :string,
      args: :json,
      time: :float,
      ram: :integer,
    )

    def self.push(log, name, args: nil, time: nil)
      json_data = { name: name, args: args, time: time, ram: Process.worker.ram_used }
      message = { text: [name, args&.pretty_hash!].join!(' '), level: :info }
      super(log, message: message, json_data: json_data)
    end
  end
end
