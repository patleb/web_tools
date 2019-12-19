class SetAuthenticatorStatementTimeout < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL.strip_sql
      ALTER ROLE authenticator SET statement_timeout = #{Setting[:pgrest_timeout]};
    SQL
  end

  def down
    execute <<-SQL.strip_sql
      ALTER ROLE authenticator SET statement_timeout = 0;
    SQL
  end
end
