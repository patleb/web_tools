class RescueError < ::StandardError
  RESCUE = '[RESCUE]'.freeze

  def message
    <<~EOF.strip
      #{RESCUE}[#{name}]
      #{data}
      #{before_backtrace}
    EOF
  end

  def name
    @name || raise(NotImplementedError)
  end

  def data
    @data || raise(NotImplementedError)
  end

  def before_backtrace; end
end
