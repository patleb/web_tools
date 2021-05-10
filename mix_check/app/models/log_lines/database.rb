module LogLines
  class Database < LogLine
    ROLLUPS_JSON_DATA = %i(
      size
      wal_size
      connections
    )

    json_attribute(
      name: :string,
      size: :integer,
      wal_size: :integer,
      connections: :integer,
      issues: :json,
      warnings: :json,
    )

    def self.rollups
      operations = ROLLUPS_JSON_DATA.map{ |field| [:maximum, field] }
      %i(week day).each_with_object({}) do |period, result|
        result[[period, :period]] = group_by_period(period).calculate(operations)
      end
    end

    def self.push(log, row)
      level = :info
      level = :warn if row.warning?
      level = :error if row.error?
      json_data = {
        connections: row.connections_total,
        issues: row.error_names(false),
        warnings: row.warning_names(false),
        **row.slice(:name, :size, :wal_size)
      }
      message = { text: [json_data[:name], (json_data[:issues] + json_data[:warnings]).uniq].join!(' '), level: level }
      super(log, message: message, json_data: json_data)
    end
  end
end
