class PgunitInstall < ActiveRecord::Migration[6.0]
  def up
    execute ExtRails::Engine.root.join('db/pgunit/PGUnit.sql').read.strip_sql[1..-1]
  end

  def down
    execute ExtRails::Engine.root.join('db/pgunit/PGUnitDrop.sql').read.strip_sql
  end
end
