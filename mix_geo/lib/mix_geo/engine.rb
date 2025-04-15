require 'ext_rails'
require 'countries'
require 'mix_geo/configuration'

module MixGeo
  class Engine < Rails::Engine
    config.before_initialize do
      Rails.autoloaders.main.ignore("#{root}/app/models/postgis") unless Setting[:postgis]
    end

    initializer 'mix_geo.migrations' do |app|
      append_migrations(app)
      append_migrations(app, scope: 'postgis') if Setting[:postgis]
    end

    initializer 'mix_geo.backup' do
      ExtRails.config.temporary_tables.merge(%w(cities countries ips states).map{ |name| "lib_geo_#{name}" })
      ExtRails.config.excluded_tables.merge(%w(spatial_ref_sys topology layer)) if Setting[:postgis]
    end

    initializer 'mix_geo.compile_vars' do
      ExtRice.configure do |config|
        config.compile_vars[:netcdf] = {
          'Numo::Int8'   => 'NC_BYTE',
          'Numo::Int16'  => 'NC_SHORT',
          'Numo::Int32'  => 'NC_INT',
          'Numo::Int64'  => 'NC_INT64',
          'Numo::SFloat' => 'NC_FLOAT',
          'Numo::DFloat' => 'NC_DOUBLE',
          'Numo::UInt8'  => 'NC_UBYTE',
          'Numo::UInt16' => 'NC_USHORT',
          'Numo::UInt32' => 'NC_UINT',
          'Numo::UInt64' => 'NC_UINT64',
        }
      end
    end

    ActiveSupport.on_load(:active_record) do
      if Setting[:postgis]
        ENV['PROJ_IGNORE_CELESTIAL_BODY'] = 'YES'
        require 'rgeo/proj4'
        require 'activerecord-postgis-adapter'
        require 'mix_geo/active_record/migration/with_postgis'
      end
      MixSearch.config.available_types['GeoState'] = 10
    end
  end
end
