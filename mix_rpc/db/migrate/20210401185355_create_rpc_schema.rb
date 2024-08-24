class CreateRpcSchema < ActiveRecord::Migration[7.1]
  def change
    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          CREATE SCHEMA IF NOT EXISTS rpc;
          GRANT USAGE ON SCHEMA rpc TO public;
        SQL
      end
      change.down do
        execute <<-SQL.strip_sql
          REVOKE USAGE ON SCHEMA rpc FROM public;
          DROP SCHEMA rpc;
        SQL
      end
    end
  end
end
