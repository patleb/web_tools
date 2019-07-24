class AddHealthcheckFunctionToApiSchema < ActiveRecord::Migration[5.2]
  def up
    exec_query <<-SQL.strip_sql
      CREATE OR REPLACE FUNCTION api.healthcheck() RETURNS BOOLEAN AS $$
        BEGIN
          RETURN TRUE;
        END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL
  end

  def down
    exec_query <<-SQL
      DROP FUNCTION IF EXISTS api.healthcheck();
    SQL
  end
end
