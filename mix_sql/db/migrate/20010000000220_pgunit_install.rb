class PgunitInstall < ActiveRecord::Migration[6.0]
  def up
    execute MixSql::Engine.root.join('db/PGUnit.sql').read.strip_sql[1..-1]
  end

  def down
    execute MixSql::Engine.root.join('db/PGUnitDrop.sql').read.strip_sql
  end
end
