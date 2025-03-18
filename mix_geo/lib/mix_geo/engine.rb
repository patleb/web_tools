require 'ext_rails'
require 'countries'
require 'mix_geo/configuration'

module MixGeo
  class Engine < ::Rails::Engine
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
          'numo::Int8'   => ['NC_BYTE',   'int8_t'],
          'numo::Int16'  => ['NC_SHORT',  'int16_t'],
          'numo::Int32'  => ['NC_INT',    'int32_t'],
          'numo::Int64'  => ['NC_INT64',  'int64_t2'],
          'numo::SFloat' => ['NC_FLOAT',  'float'],
          'numo::DFloat' => ['NC_DOUBLE', 'double'],
          'numo::UInt8'  => ['NC_UBYTE',  'uint8_t'],
          'numo::UInt16' => ['NC_USHORT', 'uint16_t'],
          'numo::UInt32' => ['NC_UINT',   'uint32_t'],
          'numo::UInt64' => ['NC_UINT64', 'uint64_t2'],
        }
      end
    end

    ActiveSupport.on_load(:active_record) do
      if Setting[:postgis]
        require 'activerecord-postgis-adapter'
        require 'mix_geo/active_record/migration/with_postgis'
      end
      MixSearch.config.available_types['GeoState'] = 10
    end
  end
end
