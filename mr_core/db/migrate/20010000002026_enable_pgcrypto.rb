class EnablePgcrypto < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto'

    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          CREATE OR REPLACE FUNCTION md5_hex(value TEXT) RETURNS TEXT AS $$
          BEGIN
            RETURN encode(digest(value, 'md5'), 'hex');
          END;
          $$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;
        SQL
      end

      change.down do
        execute <<-SQL.strip_sql
          DROP FUNCTION IF EXISTS md5_hex(value TEXT);
        SQL
      end
    end
  end
end
