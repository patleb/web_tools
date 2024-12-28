module ActiveRecord::Migration::WithGeometry
  def add_geometry_column(table_name, column_name, null: true)
    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          ALTER TABLE #{table_name} ADD COLUMN #{column_name} GEOMETRY#{' NOT NULL' unless null};
        SQL
      end
      change.down do
        execute <<-SQL.strip_sql
          ALTER TABLE #{table_name} DROP COLUMN #{column_name};
        SQL
      end
    end
  end
end

ActiveRecord::Migration.include ActiveRecord::Migration::WithGeometry
