module ActiveRecord::Migration::WithRaster
  def add_raster_column(table_name, column_name, null: true)
    reversible do |change|
      change.up do
        execute <<-SQL.strip_sql
          ALTER TABLE #{table_name} ADD COLUMN #{column_name} RASTER#{' NOT NULL' unless null};
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

ActiveRecord::Migration.include ActiveRecord::Migration::WithRaster
