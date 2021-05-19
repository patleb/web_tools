module LogLines
  class Database < LogLine
    json_attribute(
      name: :string,
      size: :integer,
      wal_size: :integer,
      connections: :integer,
      issues: :json,
      warnings: :json,
    )

    def self.rollups
      %i(week day).each_with_object({}) do |period, result|
        result[[period, :period]] = group_by_period(period).calculate(LogRollups::Database::OPERATIONS)
      end
    end

    def self.push(log, row)
      level = :info
      level = :warn if row.warning?
      level = :error if row.issue?
      json_data = {
        **row.slice(:name, :size, :wal_size),
        connections: row.connections_total,
        issues: row.issue_names(false),
        warnings: row.warning_names(false),
      }
      message = { text: json_data[:name], level: level }
      super(log, message: message, json_data: json_data)
    end
  end
end
