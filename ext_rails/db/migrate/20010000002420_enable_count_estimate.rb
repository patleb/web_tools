### References
# https://wiki.postgresql.org/wiki/Count_estimate
class EnableCountEstimate < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.strip_sql
      CREATE FUNCTION count_estimate(query text) RETURNS BIGINT AS $$
      DECLARE
        line RECORD;
        size BIGINT;
      BEGIN
        FOR line IN EXECUTE 'EXPLAIN ' || query LOOP
          size = substring(line."QUERY PLAN" FROM ' rows=([[:digit:]]+)');
          EXIT WHEN size IS NOT NULL;
        END LOOP;
        RETURN size;
      END
      $$ LANGUAGE plpgsql;

      CREATE FUNCTION table_estimate(name text) RETURNS BIGINT AS $$
      DECLARE
        size BIGINT;
      BEGIN
        SELECT reltuples::BIGINT INTO size FROM pg_class WHERE oid = name::regclass LIMIT 1;
        RETURN size;
      END
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<-SQL.strip_sql
      DROP FUNCTION IF EXISTS count_estimate(query text);
      DROP FUNCTION IF EXISTS table_estimate(name text);
    SQL
  end
end
