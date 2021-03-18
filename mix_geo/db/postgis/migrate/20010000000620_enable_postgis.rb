class EnablePostgis < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'postgis'
    enable_extension 'postgis_topology'
    enable_extension 'postgis_raster'
  end
end
