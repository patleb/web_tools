class RescueError < ::StandardError
  RESCUE = '[RESCUE]'.freeze

  attr_reader :name, :backtrace, :data

  def initialize(exception = self, data: nil)
    @exception = exception
    @name      ||= exception.class.name
    @backtrace ||= exception.backtrace
    @data      ||= data || {}
    @message   ||= exception.message if exception.message != @name
  end

  def message
    <<~EOF.strip
      #{RESCUE}[#{@name}]
      #{@message}
      #{@data.pretty_json}
    EOF
  end
end
