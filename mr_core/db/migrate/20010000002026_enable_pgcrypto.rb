class EnablePgcrypto < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto'

    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          CREATE OR REPLACE FUNCTION md5_hex(value ANYELEMENT) RETURNS TEXT AS $$
          BEGIN
            RETURN encode(digest(value::TEXT, 'md5'), 'hex');
          END;
          $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;

          ALTER FUNCTION md5_hex(value ANYELEMENT) SET search_path=public;
        SQL
      end

      change.down do
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS md5_hex(value ANYELEMENT);
        SQL
      end
    end
  end
end
