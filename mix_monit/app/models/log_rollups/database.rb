class LogRollups::Database < LogRollup
  OPERATIONS = [
    [:maximum, :size],
    [:maximum, :wal_size],
    [:maximum, :connections]
  ]

  json_attribute(
    size: :big_integer,
    wal_size: :big_integer,
    connections: :integer,
  )

  enum group_name: {
    period: 0,
  }
end
