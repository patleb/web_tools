class Setting
  class InvalidCheckLogPeriod < ::StandardError; end

  def self.check_log_interval
    tokens = self[:check_log_period].split('_').except('every').map(&:cast)
    case tokens.size
    when 1 then 1.send(tokens.first)
    when 2 then tokens.first.send(tokens.last)
    else        raise InvalidCheckLogPeriod
    end
  end
end
