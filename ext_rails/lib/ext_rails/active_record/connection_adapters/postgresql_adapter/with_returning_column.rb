module ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::WithReturningColumn
  def update(arel, name = nil, binds = [])
    sql_options = Thread.current[:sql_options]
    return super unless (column = sql_options&.dig(self, :returning))
    sql, binds = to_sql_and_binds(arel, binds)
    sql = "#{sql} RETURNING #{column}"
    execute_and_clear(sql, name, binds) do |result|
      values = result.field_values(column)
      values.size > 1 ? [values.size, values.first] : values.first
    end
  end
end
