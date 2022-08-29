class EnablePgcrypto < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'pgcrypto'

    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          CREATE OR REPLACE FUNCTION sha1_hex(VARIADIC args ANYARRAY) RETURNS TEXT AS $$
          BEGIN
            RETURN encode(digest(array_to_string(args::TEXT[], '.', '?'), 'sha1'), 'hex');
          END;
          $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

          CREATE OR REPLACE FUNCTION sha256_hex(VARIADIC args ANYARRAY) RETURNS TEXT AS $$
          BEGIN
            RETURN encode(digest(array_to_string(args::TEXT[], '.', '?'), 'sha256'), 'hex');
          END;
          $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

          ALTER FUNCTION sha1_hex(VARIADIC args ANYARRAY) SET search_path=public;
          ALTER FUNCTION sha256_hex(VARIADIC args ANYARRAY) SET search_path=public;
        SQL
      end

      change.down do
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS sha1_hex;
          DROP FUNCTION IF EXISTS sha256_hex;
        SQL
      end
    end
  end
end
