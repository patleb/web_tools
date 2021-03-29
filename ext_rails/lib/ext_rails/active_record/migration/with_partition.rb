module ActiveRecord::Migration::WithPartition
  PARTITION = / PARTITION .+$/i
  TABLE = / TABLE (\w+) /i

  def create_table_sql
    sql = yield.strip_sql
    sql.sub! PARTITION, '' if Rails.env.test?
    partitioned = sql.match? PARTITION
    reversible do |change|
      change.up do
        exec_query sql
      end
      change.down do
        table = sql.match(TABLE).captures[0]
        exec_query "DROP TABLE IF EXISTS #{table}#{' CASCADE' if partitioned};"
      end
    end
  end
end
