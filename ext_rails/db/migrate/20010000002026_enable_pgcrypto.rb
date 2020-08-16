class EnablePgcrypto < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'

    reversible do |change|
      change.up do
        # TODO remove DROP line
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS md5_hex(value ANYELEMENT, scope TEXT);

          CREATE OR REPLACE FUNCTION md5_hex(VARIADIC args ANYARRAY) RETURNS TEXT AS $$
          BEGIN
            RETURN encode(digest(array_to_string(args::TEXT[], '.', '?'), 'md5'), 'hex');
          END;
          $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

          ALTER FUNCTION md5_hex(VARIADIC args ANYARRAY) SET search_path=public;
        SQL
      end

      change.down do
        # TODO remove DROP line
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS md5_hex(value ANYELEMENT, scope TEXT);
          DROP FUNCTION IF EXISTS md5_hex(VARIADIC args ANYARRAY);
        SQL
      end
    end
  end
end
