# TODO allow multiple PostgREST API applications on the same server
class EnablePgrest < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL.strip_sql
      CREATE SCHEMA IF NOT EXISTS api;
      GRANT USAGE ON SCHEMA api TO public;

      DO $do$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE  rolname = 'web_anon') THEN
          CREATE ROLE web_anon NOLOGIN;
        END IF;
      END $do$;
      GRANT USAGE ON SCHEMA api TO web_anon;
      ALTER ROLE web_anon SET search_path TO api;

      DO $do$ BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '#{Setting[:pgrest_db_username]}') THEN
          CREATE ROLE #{Setting[:pgrest_db_username]} NOINHERIT LOGIN;
        END IF;
      END $do$;
      ALTER USER #{Setting[:pgrest_db_username]} WITH PASSWORD '#{Setting[:pgrest_db_password]}';
      GRANT web_anon TO #{Setting[:pgrest_db_username]};
    SQL
  end

  def down
    execute <<-SQL.strip_sql
      REVOKE web_anon FROM #{Setting[:pgrest_db_username]};
      DROP ROLE #{Setting[:pgrest_db_username]};

      REVOKE USAGE ON SCHEMA api FROM web_anon;
      DROP ROLE web_anon;

      REVOKE USAGE ON SCHEMA api FROM public;
      DROP SCHEMA api;
    SQL
  end
end
