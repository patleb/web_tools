module ActiveRecord::Migration::WithPostgis
  def add_geometry_column(*, **)
    add_postgis_column(*, 'GEOMETRY', **)
  end

  def add_raster_column(*, **)
    add_postgis_column(*, 'RASTER', **)
  end

  private

  def add_postgis_column(table_name, column_name, type, null: true)
    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          ALTER TABLE #{table_name} ADD COLUMN #{column_name} #{type}#{' NOT NULL' unless null};
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

ActiveRecord::Migration.include ActiveRecord::Migration::WithPostgis
