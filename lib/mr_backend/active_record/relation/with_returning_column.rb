# TODO update
# activerecord-5.2.3/lib/active_record/relation.rb
# activerecord-5.2.3/lib/active_record/connection_adapters/abstract/database_statements.rb
module ActiveRecord::Relation::WithReturningColumn
  def update_all(updates, column = nil)
    return super(updates) unless column

    raise ArgumentError, "Empty list of attributes to change" if updates.blank?

    stmt = Arel::UpdateManager.new

    stmt.set Arel.sql(@klass.send(:sanitize_sql_for_assignment, updates))
    stmt.table(table)

    if has_join_values? || offset_value
      @klass.connection.join_to_update(stmt, arel, arel_attribute(primary_key))
    else
      stmt.key = arel_attribute(primary_key)
      stmt.take(arel.limit)
      stmt.order(*arel.orders)
      stmt.wheres = arel.constraints
    end

    sql, binds = @klass.connection.send(:to_sql_and_binds, stmt)
    sql = "#{sql} RETURNING #{column}"

    @klass.connection.send(:execute_and_clear, sql, "SQL", binds) do |result|
      result.field_values(column).first
    end
  end
end
