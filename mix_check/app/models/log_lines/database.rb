module LogLines
  class Database < LogLine
    json_attribute(
      name: :string,
      size: :integer,
      wal_size: :integer,
      connections: :integer,
      queries: :float,
      errors: :json,
    )

    def self.push(log, row)
      level = :info
      level = :warn if row.warning?
      level = :error if row.error?
      json_data = {
        connections: row.connections_total,
        queries: row.queries.duration,
        errors: row.errors.attribute_names,
        **row.slice(:name, :size, :wal_size)
      }
      message = { text: json_data.values_at(:name, :errors).join!(' '), level: level }
      super(log, message: message, json_data: json_data)
    end

    def self.rollups
      # TODO size, wal_size, connections, queries
    end
  end
end
