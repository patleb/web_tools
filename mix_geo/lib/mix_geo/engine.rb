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
      ExtRails.config.temporary_tables.merge(%w(lib_geo_cities lib_geo_countries lib_geo_ips lib_geo_states))
      ExtRails.config.excluded_tables.merge(%w(spatial_ref_sys topology layer)) if Setting[:postgis]
    end

    initializer 'mix_geo.template', before: 'ext_rice.require_ext' do
      ExtRice.configure do |config|
        config.template[:matio] = {
          # 'Int8'   => 'MAT_C_INT8',   # 8
          # 'Int16'  => 'MAT_C_INT16',  # 10
          'Int32'  => 'MAT_C_INT32',  # 12
          'Int64'  => 'MAT_C_INT64',  # 14
          'SFloat' => 'MAT_C_SINGLE', # 5
          'DFloat' => 'MAT_C_DOUBLE', # 6
          'UInt8'  => 'MAT_C_UINT8',  # 9
          # 'UInt16' => 'MAT_C_UINT16', # 11
          # 'UInt32' => 'MAT_C_UINT32', # 13
          # 'UInt64' => 'MAT_C_UINT64', # 15
        }
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
        }
        %i(matio netcdf).each do |types|
          raise 'types mismatch' if config.template[types].keys != config.template[:numeric].keys
        end
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
