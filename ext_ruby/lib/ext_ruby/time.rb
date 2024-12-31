class Time
  def self.today
    current.beginning_of_day
  end

  def self.parse_utc(...)
    find_zone('UTC').parse(...)
  end
end
