# activerecord-6.0.2.1/lib/active_record/relation.rb
# activerecord-6.0.2.1/lib/active_record/connection_adapters/abstract/database_statements.rb
# activerecord-6.0.2.1/lib/active_record/connection_adapters/postgresql/database_statements.rb
module ActiveRecord::Relation::WithReturningColumn
  def update_all(updates, column = nil)
    return super(updates) unless column

    raise ArgumentError, "Empty list of attributes to change" if updates.blank?

    if eager_loading?
      relation = apply_join_dependency
      return relation.update_all(updates, column)
    end

    stmt = Arel::UpdateManager.new
    stmt.table(arel.join_sources.empty? ? table : arel.source)
    stmt.key = table[primary_key]
    stmt.take(arel.limit)
    stmt.offset(arel.offset)
    stmt.order(*arel.orders)
    stmt.wheres = arel.constraints

    if updates.is_a?(Hash)
      if klass.locking_enabled? &&
        !updates.key?(klass.locking_column) &&
        !updates.key?(klass.locking_column.to_sym)
        attr = table[klass.locking_column]
        updates[attr.name] = _increment_attribute(attr)
      end
      stmt.set _substitute_values(updates)
    else
      stmt.set Arel.sql(klass.sanitize_sql_for_assignment(updates, table.name))
    end

    sql, binds = @klass.connection.send(:to_sql_and_binds, stmt)
    sql = "#{sql} RETURNING #{column}"

    # TODO generalize for result set
    @klass.connection.send(:execute_and_clear, sql, "#{@klass} Update All", binds) do |result|
      result.field_values(column).first
    end
  end
end
