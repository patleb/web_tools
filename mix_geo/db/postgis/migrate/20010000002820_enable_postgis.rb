class EnablePostgis < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'postgis'
    enable_extension 'postgis_topology'
    enable_extension 'postgis_raster' unless select_value('SELECT postgis_version()').split.first.to_f < 3.0
  end
end
