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
    requests: :integer,
    time_min: :float,
    time_max: :float,
    time_avg: :float,
    time_std: :float,
    time_med: :float,
    bytes_out: :integer,
    bytes_in: :integer,
    users: :integer,
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
end
