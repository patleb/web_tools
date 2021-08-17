module LogLines
  class Rescue < LogLine
    json_attribute(
      error: :string,
      exception: :string,
      data: :json,
      ram: :big_integer
    )

    def self.push(log, exception, data: nil)
      unless exception.is_a? RescueError
        exception = RescueError.new(exception, data: data)
      end
      json_data = {
        error: exception.class.name,
        exception: exception.name,
        data: exception.data,
        ram: Process.worker.ram_used
      }
      message = { text: exception.backtrace_log, level: :error, monitor: false }
      super(log, message: message, json_data: json_data)
    end
  end
end
