class RescueError < ::StandardError
  RESCUE = '[RESCUE]'.freeze
  EXCLUDED_ERROR_SUFFIXES = IceNine.deep_freeze(%w(
    .include.rb
    .prepend.rb
    _decorator.rb
    /base.rb
  ))

  delegate :backtrace, to: :@exception
  attr_reader :name, :data

  def self.rescue_class
    if name != 'RescueError' && name.end_with?('Error')
      ActiveSupport::Dependencies.safe_constantize(name.sub(/Error$/, 'Rescue')) || Rescue
    else
      Rescue
    end
  end

  def self.viable_errors
    @viable_errors ||= Rails.viable_names('errors', MixRescue.config.excluded_errors, EXCLUDED_ERROR_SUFFIXES)
  end

  def initialize(exception, data = nil)
    @exception = exception
    @name = exception.class.name
    @data = data || {}
  end

  def message
    <<~EOF.strip
      #{RESCUE}[#{name}]
      #{data.pretty_json}
      #{before_backtrace}
    EOF
  end

  def before_backtrace
    @exception.message
  end
end
