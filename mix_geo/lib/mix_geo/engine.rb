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
          'numo::Int8'   => 'NC_BYTE',
          'numo::Int16'  => 'NC_SHORT',
          'numo::Int32'  => 'NC_INT',
          'numo::Int64'  => 'NC_INT64',
          'numo::SFloat' => 'NC_FLOAT',
          'numo::DFloat' => 'NC_DOUBLE',
          'numo::UInt8'  => 'NC_UBYTE',
          'numo::UInt16' => 'NC_USHORT',
          'numo::UInt32' => 'NC_UINT',
          'numo::UInt64' => 'NC_UINT64',
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
