module ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::WithUnaccent
  def add_unaccent(table, *columns)
    exec_query <<-SQL.strip_sql
      CREATE TRIGGER #{unaccent_trigger_name(table, columns)}
        BEFORE INSERT OR UPDATE ON #{table}
        FOR EACH ROW EXECUTE FUNCTION unaccent_text('#{columns.join("', '")}');
    SQL
  end

  def remove_unaccent(table, *columns)
    exec_query <<-SQL.strip_sql
      DROP TRIGGER IF EXISTS #{unaccent_trigger_name(table, columns)} ON #{table}
    SQL
  end

  private

  def unaccent_trigger_name(table, columns)
    "unaccent_on_#{columns.join('_')}_of_#{table}"[0..62]
  end
end
