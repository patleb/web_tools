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
          types: {
            'numo::Int8'   => ['NC_BYTE',   'int8_t',    'schar'],
            'numo::Int16'  => ['NC_SHORT',  'int16_t',   'short'],
            'numo::Int32'  => ['NC_INT',    'int32_t',   'int'],
            'numo::Int64'  => ['NC_INT64',  'int64_t2',  'longlong'],
            'numo::SFloat' => ['NC_FLOAT',  'float',     'float'],
            'numo::DFloat' => ['NC_DOUBLE', 'double',    'double'],
            'numo::UInt8'  => ['NC_UBYTE',  'uint8_t',   'uchar'],
            'numo::UInt16' => ['NC_USHORT', 'uint16_t',  'ushort'],
            'numo::UInt32' => ['NC_UINT',   'uint32_t',  'uint'],
            'numo::UInt64' => ['NC_UINT64', 'uint64_t2', 'ulonglong'],
          }
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
