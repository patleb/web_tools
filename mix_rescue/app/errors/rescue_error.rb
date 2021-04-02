class RescueError < ::StandardError
  RESCUE = '[RESCUE]'.freeze

  delegate :backtrace, to: :@exception
  attr_reader :name, :data

  def initialize(exception = self, data: nil)
    @exception = exception
    @name = exception.class.name
    @data = data || {}
    @message = exception.message if exception.message != @name
  end

  def message
    <<~EOF.strip
      #{RESCUE}[#{@name}]
      #{@message}
      #{@data.pretty_json}
    EOF
  end
end
