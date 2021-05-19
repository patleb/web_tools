class LogRollups::Database < LogRollup
  OPERATIONS = [
    [:maximum, :size],
    [:maximum, :wal_size],
    [:maximum, :connections]
  ]

  json_attribute(
    size: :integer,
    wal_size: :integer,
    connections: :integer,
  )

  enum group_name: {
    period: 0,
  }
end
