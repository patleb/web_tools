require 'ext_rails'
require 'countries'
require 'mix_geo/configuration'

module MixGeo
  class Engine < ::Rails::Engine
    config.before_initialize do
      Rails.autoloaders.main.ignore("#{root}/app/models/postgis") unless Setting[:postgis_enabled]
    end

    initializer 'mix_geo.migrations' do |app|
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
      MixSearch.config.available_types['GeoState'] = 10
    end
  end
end
