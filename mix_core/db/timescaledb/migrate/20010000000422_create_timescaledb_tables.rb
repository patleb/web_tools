class CreateTimescaledbTables < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.strip_sql
      CREATE VIEW timescaledb_tables AS
        SELECT id, table_name AS name,
          COALESCE(total_bytes, 0) AS total_bytes,
          COALESCE(table_bytes, 0) AS table_bytes,
          COALESCE(index_bytes, 0) AS index_bytes,
          COALESCE(toast_bytes, 0) AS toast_bytes
        FROM (
          SELECT id, table_name, (hypertable_relation_size(table_name::regclass)).* FROM _timescaledb_catalog.hypertable
        ) tables;
    SQL
  end

  def down
    execute <<-SQL.strip_sql
      DROP VIEW timescaledb_tables;
    SQL
  end
end
