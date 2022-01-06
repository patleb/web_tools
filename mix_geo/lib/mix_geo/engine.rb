require 'ext_ruby'
require 'countries'
require 'rgeo'
require 'mix_geo/configuration'
require 'mix_geo/countries/country'

module MixGeo
  class Engine < ::Rails::Engine
    config.before_initialize do
      Rails.autoloaders.main.ignore("#{root}/app/models/postgis") unless Setting[:postgis_enabled]
    end

    initializer 'mix_geo.append_migrations' do |app|
      append_migrations(app)
      append_migrations(app, scope: 'postgis') if Setting[:postgis_enabled]
    end

    initializer 'mix_geo.backup' do
      ExtRails.config.temporary_tables.merge(%w(cities countries ips states).map{ |name| "lib_geo_#{name}" })
      ExtRails.config.excluded_tables.merge(%w(spatial_ref_sys topology layer)) if Setting[:postgis_enabled]
    end

    ActiveSupport.on_load(:active_record) do
      if Setting[:postgis_enabled]
        require 'activerecord-postgis-adapter'
        require 'mix_geo/active_record/migration/with_raster'
      end

      MixLog.config.filter_parameters += %w(
        CRS
        SRS
        TILED
        STYLES
        TRANSPARENT
        REQUEST
        SERVICE
        VERSION
        FORMAT
        FORMAT_OPTIONS
        HEIGHT
      )
      MixSearch.config.available_types['GeoState'] = 10
    end
  end
end
