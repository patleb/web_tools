class LogRollups::Database < LogRollup
  json_attribute(
    size: :integer,
    wal_size: :integer,
    connections: :integer,
  )

  enum group_name: {
    period: 0,
  }
end
