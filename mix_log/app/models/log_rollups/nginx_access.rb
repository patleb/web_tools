class LogRollups::NginxAccess < LogRollup
  OPERATIONS = [
    [:count],
    [:minimum, :time],
    [:maximum, :time],
    [:average, :time],
    [:stddev,  :time],
    [:median,  :time],
    [:sum,     :bytes_out],
    [:sum,     :bytes_in],
  ]

  json_attribute(
    requests: :big_integer,
    time_min: :float,
    time_max: :float,
    time_avg: :float,
    time_std: :float,
    time_med: :float,
    bytes_out: :big_integer,
    bytes_in: :big_integer,
    users: :big_integer,
    hours: :json,
  )

  enum group_name: {
    period: 0,
    path: 10,
    status: 20,
    referer: 30,
    country: 40,
    state: 50,
    browser: 60,
    platform: 70,
  }

  def self.requests_begin_at
    where(period: 1.day).order(:period_at).pick(:period_at)&.utc
  end

  def self.requests_end_at
    where(period: 1.day).order(period_at: :desc).pick(:period_at)&.utc
  end

  def self.total_requests
    where(period: 1.week).period.order(period_at: :desc).sum(:requests).to_i
  end

  def self.total_bytes_out
    where(period: 1.week).period.sum(:bytes_out).to_fs(:human_size)
  end

  def self.requests_by(period_or_group)
    case period_or_group
    when :month
      period.where(period: 1.day).group_by_period(:month, column: :period_at, reverse: true).sum(:requests).map do |(date, sum)|
        [date.strftime('%Y-%m-%d'), sum.to_i]
      end
    when :week, :day
      period.where(period: 1.send(period_or_group)).order(period_at: :desc).group(:period_at).sum(:requests).map do |(date, sum)|
        [date.strftime('%Y-%m-%d'), sum.to_i]
      end
    else
      send(period_or_group).top_group_calculate(:group_value, :sum, column: :requests).map do |(group, sum)|
        [group, sum.to_i]
      end
    end
  end

  def self.users_by(period = :week)
    log_path = MixLog.config.passenger_log_path(:access)
    joins(:log).period.where(period: 1.send(period), log: { path: log_path }).order(period_at: :desc).map do |row|
      [row.period_at.strftime('%Y-%m-%d'), row.users]
    end
  end
end
