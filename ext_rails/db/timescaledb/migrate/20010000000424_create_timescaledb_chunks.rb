class CreateTimescaledbChunks < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.strip_sql
      CREATE VIEW timescaledb_chunks AS
        SELECT id || '_' || chunk_id AS id, table_name, id AS table_id, chunk_id, ranges[1] AS range,
          COALESCE(total_bytes, 0) AS total_bytes,
          COALESCE(table_bytes, 0) AS table_bytes,
          COALESCE(index_bytes, 0) AS index_bytes,
          COALESCE(toast_bytes, 0) AS toast_bytes
        FROM (
          SELECT id, table_name, (chunk_relation_size(table_name::regclass)).* FROM _timescaledb_catalog.hypertable
        ) chunks;
    SQL
  end

  def down
    execute <<-SQL.strip_sql
      DROP VIEW timescaledb_chunks;
    SQL
  end
end
