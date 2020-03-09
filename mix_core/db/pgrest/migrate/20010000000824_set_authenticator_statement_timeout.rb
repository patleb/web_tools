class SetAuthenticatorStatementTimeout < ActiveRecord::Migration[6.0]
  def up
    pgrest_timeout = Setting[:pgrest_timeout]
    pgrest_timeout = case
      when pgrest_timeout >= 60_000
        pgrest_timeout - 10_000
      when pgrest_timeout >= 30_000
        pgrest_timeout - 5_000
      else
        pgrest_timeout - 1_000
      end
    execute <<-SQL.strip_sql
      ALTER ROLE authenticator SET statement_timeout = #{pgrest_timeout};
    SQL
  end

  def down
    execute <<-SQL.strip_sql
      ALTER ROLE authenticator SET statement_timeout = 0;
    SQL
  end
end
