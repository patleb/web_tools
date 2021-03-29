require 'ext_ruby'
require 'countries'
require 'rgeo'
require 'reversed'
require 'mix_geo/configuration'
require 'mix_geo/countries/country'

module MixGeo
  class Engine < ::Rails::Engine
    config.before_initialize do
      unless Setting[:postgis_enabled]
        Rails.autoloaders.main.ignore("#{root}/app/models/postgis")
      end
    end

    initializer 'mix_geo.append_migrations' do |app|
      append_migrations(app)
      append_migrations(app, scope: 'postgis') if Setting[:postgis_enabled]
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
