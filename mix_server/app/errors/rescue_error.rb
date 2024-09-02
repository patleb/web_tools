# frozen_string_literal: true

class RescueError < ::StandardError
  RESCUE = '[RESCUE]'

  attr_reader :error, :name, :backtrace, :data

  def initialize(exception = self, data: nil)
    @error       = exception
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
