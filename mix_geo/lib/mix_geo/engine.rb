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

    initializer 'mix_geo.template', before: 'ext_rice.require_ext' do
      ExtRice.configure do |config|
        config.template[:netcdf] = {
          # 'Int8'   => 'NC_BYTE',   # 1
          # 'Int16'  => 'NC_SHORT',  # 3
          'Int32'  => 'NC_INT',    # 4
          'Int64'  => 'NC_INT64',  # 10
          'SFloat' => 'NC_FLOAT',  # 5
          'DFloat' => 'NC_DOUBLE', # 6
          'UInt8'  => 'NC_UBYTE',  # 7
          # 'UInt16' => 'NC_USHORT', # 8
          # 'UInt32' => 'NC_UINT',   # 9
          # 'UInt64' => 'NC_UINT64', # 11
          # 'String' => 'NC_CHAR',   # 2
        }
        raise "types mismatch" if config.template[:netcdf].keys != config.template[:numeric].keys
      end
    end

    ActiveSupport.on_load(:active_record) do
      if Setting[:postgis]
        ENV['PROJ_IGNORE_CELESTIAL_BODY'] = 'YES'
        require 'activerecord-postgis-adapter'
        require 'mix_geo/active_record/migration/with_postgis'
      end
      MixSearch.config.available_types['GeoState'] = 10
    end
  end
end
