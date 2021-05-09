class Setting
  class InvalidCheckPeriod < ::StandardError; end

  def self.check_database_interval
    tokens = self[:check_database_period].split('_').except('every').map(&:cast)
    case tokens.size
    when 1 then 1.send(tokens.first)
    when 2 then tokens.first.send(tokens.last)
    else        raise InvalidCheckPeriod
    end
  end
end
