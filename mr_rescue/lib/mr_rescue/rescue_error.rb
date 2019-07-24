class RescueError < ::StandardError
  RESCUE = '[RESCUE]'.freeze

  def message
    <<~EOF.strip
      #{RESCUE}[#{name}]
      #{data}
      #{after_message}
    EOF
  end

  def name
    @name || raise(NotImplementedError)
  end

  def data
    @data || raise(NotImplementedError)
  end

  def after_message; end
end
