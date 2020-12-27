module MixGeo
  class CreateIps < ActiveTask::Base
    class PathWithoutVersion < ::ArgumentError; end
    class PathInvalid < ::ArgumentError; end

    GEO_TABLES           = ['lib_geo_ips', 'lib_geo_cities', 'lib_geo_states', 'lib_geo_countries']
    GEOLITE2_CSV         = 'geolite2-city-ipv4.csv'
    TMP_GEOLITE2_FOLDER  = 'tmp/geolite2'
    TMP_GEOLITE2_CSV     = "#{TMP_GEOLITE2_FOLDER}/#{GEOLITE2_CSV}"
    TMP_GEOLITE2_CSV_GZ  = "#{TMP_GEOLITE2_CSV}.gz"
    TMP_GEOLITE2_PREFIX  = "#{TMP_GEOLITE2_FOLDER}-ipv4-"
    GIT_GEOLITE2_CSV_GZ  = "https://raw.githubusercontent.com/sapics/ip-location-db/master/geolite2-city/#{GEOLITE2_CSV}.gz"
    GIT_GEOLITE2_VERSION = "https://raw.githubusercontent.com/sapics/ip-location-db/master/geolite2-city/package.json"
    GEM_GEOLITE2_CSV     = Gem.root('ip_location_db').join('geolite2-city', GEOLITE2_CSV).to_s
    GEM_GEOLITE2_CSV_GZ  = "#{GEM_GEOLITE2_CSV}.gz"

    def self.args
      {
        remote:  ['--[no-]remote',     'Use the remote CSV from Github'],
        path:    ['--path=PATH',       'Use the local CSV under the directory specified', :exist],
        version: ['--version=VERSION', 'The version of the CSV specified by --path (required)']
      }
    end

    def self.steps
      [
        :prepare_csv_file,
        :truncate_tables,
        :create_countries_and_states,
        :extract_csv_and_split,
        :create_cities_and_ips,
        :save_version
      ]
    end

    def prepare_csv_file
      mkdir_p TMP_GEOLITE2_FOLDER, verbose: false
      version_was = Gem::Version.new((ActiveRecord::InternalMetadata[:geolite2_version] || '0.0.0'))
      if options.remote
        @version = Gem::Version.new(JSON.parse(open(GIT_GEOLITE2_VERSION))['version'])
        if @version > version_was
          IO.copy_stream(open(GIT_GEOLITE2_CSV_GZ), TMP_GEOLITE2_CSV_GZ)
          puts_info 'VERSION', "New GeoLite2 version [#{@version}] downloaded in #{TMP_GEOLITE2_FOLDER} folder"
          @csv_file  = TMP_GEOLITE2_CSV
          @gzip_file = TMP_GEOLITE2_CSV_GZ
        end
      elsif options.path.present?
        raise PathWithoutVersion unless options.version.present?
        @version = Gem::Version.new(options.version)
        @csv_file  = "#{options.path}/#{GEOLITE2_CSV}"
        @gzip_file = "#{@csv_file}.gz"
        raise PathInvalid unless File.exist? @gzip_file
      else
        @version   = Gem.loaded_specs['ip_location_db'].version
        @csv_file  = GEM_GEOLITE2_CSV
        @gzip_file = GEM_GEOLITE2_CSV_GZ
      end

      if @version > version_was
        remove_tmp_files
      else
        puts_info 'VERSION', 'GeoLite2 is already up-to-date'
        cancel!
      end
    end

    def truncate_tables
      Db::Pg::Truncate.new(rake, task, includes: GEO_TABLES).run!
    end

    def create_countries_and_states
      @countries, states = MixGeo.config.extra_countries.dup, []
      ISO3166::Country.countries.each do |country|
        country_code, country_id = country.alpha2.upcase, country.number
        country.states.each do |code, state|
          state_code, state_code_prefix = code.upcase, "#{country_code}-"
          state_code = [state_code_prefix, state_code].join unless state_code.start_with? state_code_prefix
          state_names = [state.name, Array.wrap(state.unofficial_names), state.translations['en']].flatten.compact.uniq
          states << { code: state_code, names: state_names, country_code: country_code, geo_country_id: country_id }
        end if country_code.in?(MixGeo.config.supported_countries)
        @countries << { id: country_id, code: country_code, name: country.name }
      end
      GeoCountry.insert_all! @countries
      GeoState.insert_all! states
      GeoState.all.each(&:update_searches)
    end

    def extract_csv_and_split
      sh 'unpigz', '--keep', @gzip_file, verbose: false
      sh 'split', '-l', '100000', '-d', '--additional-suffix', '.csv', @csv_file, TMP_GEOLITE2_PREFIX, verbose: false
    end

    def create_cities_and_ips
      @countries = @countries.map{ |country| country.values_at(:code, :id) }.to_h
      Parallel.each(tmp_files_glob) do |file|
        cities = Set.new
        cities_ids = {}
        states_ids = {}
        states_codes = {}
        ips = BulkProcessor.new(10000) do |ips|
          GeoIp.insert_all! ips
        end
        CSV.foreach(file) do |row|
          ip_first, ip_last, country_code, state_code, state_alt, city, _postcode, latitude, longitude, _timezone = row
          country_id = @countries[country_code]
          state_search = [country_code, state_code, state_alt].compact
          state_id = states_ids[state_search]
          state_code = states_codes[state_id]
          if state_id.nil? && state_search.size > 1 && country_code.in?(MixGeo.config.supported_countries)
            state_record = GeoState.find_by_similarity(*state_search)
            state_id = states_ids[state_search] = state_record.id
            state_code = states_codes[state_id] = state_record.code
          end
          if city
            cities_size_was = cities.size
            city = {
              name: city, state_code: state_code, country_code: country_code,
              geo_country_id: country_id, geo_state_id: state_id
            }
            cities << city
            if cities.size > cities_size_was
              cities_ids[city] = GeoCity.insert(city).pluck('id').first
              cities_ids[city] ||= GeoCity.find_by(city.slice(:country_code, :state_code, :name)).id
            end
          end
          ips << {
            ip_first: ip_first, ip_last: ip_last, state_code: state_code, country_code: country_code,
            geo_country_id: country_id, geo_state_id: state_id, geo_city_id: cities_ids[city],
            latitude: latitude.to_f, longitude: longitude.to_f
          }
          ips.process
        end
        ips.finalize
      end
      GeoIp.insert_all! MixGeo.config.extra_ips
    end

    def save_version
      remove_tmp_files
      ActiveRecord::InternalMetadata[:geolite2_version] = @version.to_s
    end

    private

    def remove_tmp_files
      sh 'rm', '--force', @csv_file, verbose: false
      tmp_files_glob.each{ |file| File.delete(file) }
    end

    def tmp_files_glob
      Dir.glob("#{TMP_GEOLITE2_PREFIX}*")
    end
  end
end
