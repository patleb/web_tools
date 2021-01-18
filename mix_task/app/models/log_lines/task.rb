module LogLines
  class Task < LogLine
    json_attribute(
      pid: :integer,
      name: :string,
      args: :json,
      time: :float,
    )

    def self.push(log, name, args: nil, time: nil)
      json_data = { pid: Process.pid, name: name, args: args, time: time }
      label = { text: [name, args.presence&.pretty_hash].join!(' '), level: :info }
      super(log, label: label, json_data: json_data)
    end
  end
end
