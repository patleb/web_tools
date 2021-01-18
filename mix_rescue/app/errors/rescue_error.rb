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
      #{@data.pretty_json}
      #{@message}
    EOF
  end
end
