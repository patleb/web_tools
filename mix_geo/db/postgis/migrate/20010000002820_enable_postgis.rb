class EnablePostgis < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'postgis'
    enable_extension 'postgis_topology'
    enable_extension 'postgis_raster' unless select_value('SELECT postgis_version()').split.first.to_f < 3.0
  end
end
