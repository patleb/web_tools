class PgunitInstall < ActiveRecord::Migration[5.2]
  def up
    execute ExtSql::Engine.root.join('db/PGUnit.sql').read.strip_sql[1..-1]
  end

  def down
    execute ExtSql::Engine.root.join('db/PGUnitDrop.sql').read.strip_sql
  end
end
