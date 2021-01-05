module LogLines
  class Rescue < LogLine
    THROTTLER_KEY_PREFIX = 'log_lines_rescue'

    json_attribute :exception

    def self.push(log_id, exception, message = nil, throttle: true)
      exception = RescueError.new(exception) unless exception.is_a? RescueError
      message ||= exception.message
      exception = exception.name
      message_hash = Digest.md5_hex(exception, message.squish_numbers.squish!)

      insert log_id: log_id, message: message, message_hash: message_hash, json_data: { exception: exception }

      if throttle
        !Throttler.status(key: [THROTTLER_KEY_PREFIX, message_hash])[:throttled]
      else
        true
      end
    end
  end
end
