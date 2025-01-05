class CreateAddHealthcheckToRpcSchema < ActiveRecord::Migration[8.0]
  def change
    reversible do |change|
      change.up do
        exec_query <<-SQL.strip_sql
          CREATE OR REPLACE FUNCTION rpc.healthcheck() RETURNS BOOLEAN AS $$
            BEGIN
              RETURN TRUE;
            END;
          $$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER;
        SQL
      end
      change.down do
        exec_query <<-SQL
          DROP FUNCTION IF EXISTS rpc.healthcheck;
        SQL
      end
    end
  end
end
