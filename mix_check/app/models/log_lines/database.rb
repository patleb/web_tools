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
      errors: :json,
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
        errors: row.errors.attribute_names,
        **row.slice(:name, :size, :wal_size)
      }
      message = { text: json_data.values_at(:name, :errors).join!(' '), level: level }
      super(log, message: message, json_data: json_data)
    end
  end
end
