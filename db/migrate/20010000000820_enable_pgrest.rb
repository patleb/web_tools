class EnablePgrest < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL.strip_sql
      CREATE SCHEMA api;
      GRANT USAGE ON SCHEMA api TO public;

      CREATE ROLE web_anon NOLOGIN;
      GRANT USAGE ON SCHEMA api TO web_anon;
      ALTER ROLE web_anon SET search_path TO api;

      CREATE ROLE #{Secret[:pgrest_username]} NOINHERIT LOGIN;
      ALTER USER #{Secret[:pgrest_username]} WITH PASSWORD '#{Secret[:pgrest_password]}';
      GRANT web_anon TO #{Secret[:pgrest_username]};
    SQL
  end

  def down
    execute <<-SQL.strip_sql
      REVOKE web_anon FROM #{Secret[:pgrest_username]};
      DROP ROLE #{Secret[:pgrest_username]};

      REVOKE USAGE ON SCHEMA api FROM web_anon;
      DROP ROLE web_anon;

      REVOKE USAGE ON SCHEMA api FROM public;
      DROP SCHEMA api;
    SQL
  end
end
