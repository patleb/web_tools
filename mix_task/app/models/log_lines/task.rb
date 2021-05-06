module LogLines
  class Task < LogLine
    json_attribute(
      name: :string,
      args: :json,
      time: :float,
    )

    def self.push(log, name, args: nil, time: nil)
      json_data = { name: name, args: args, time: time }
      message = { text: [name, args&.pretty_hash!].join!(' '), level: :info }
      super(log, message: message, json_data: json_data)
    end
  end
end
