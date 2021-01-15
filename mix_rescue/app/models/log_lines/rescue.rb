module LogLines
  class Rescue < LogLine
    json_attribute(
      error: :string,
      exception: :string,
      data: :json,
    )

    def self.push(log, exception, data: nil)
      exception = RescueError.new(exception, data: data) unless exception.is_a? RescueError
      json_data = { error: exception.class.name, exception: exception.name, data: exception.data }
      label = { text: exception.backtrace_log, level: :error }
      super(log, label: label, json_data: json_data)
    end
  end
end
