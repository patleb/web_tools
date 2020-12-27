module MixGeo
  class CreateIps < ActiveTask::Base
    SUPPORTED_COUNTRIES = ['US', 'CA']
    EXTRA_COUNTRIES = [
      { id: 916, code: 'XA', name: 'Host' },
      { id: 917, code: 'XB', name: 'Private Network' },
      { id: 926, code: 'XK', name: 'Kosovo' },
    ]
    EXTRA_IPS = [
      { ip_first: '127.0.0.0',   ip_last: '127.255.255.255', country_code: 'XA', geo_country_id: 916, latitude: 0.0, longitude: 0.0 },
      { ip_first: '10.0.0.0',    ip_last: '10.255.255.255',  country_code: 'XB', geo_country_id: 917, latitude: 0.0, longitude: 0.0 },
      { ip_first: '172.16.0.0',  ip_last: '172.31.255.255',  country_code: 'XB', geo_country_id: 917, latitude: 0.0, longitude: 0.0 },
      { ip_first: '192.168.0.0', ip_last: '192.168.255.255', country_code: 'XB', geo_country_id: 917, latitude: 0.0, longitude: 0.0 },
    ]
    GEOLITE2_CSV = 'geolite2-city-ipv4.csv'
    TMP_GEOLITE2_FOLDER = 'tmp/geolite2-city'
    TMP_GEOLITE2_CSV = "#{TMP_GEOLITE2_FOLDER}/#{GEOLITE2_CSV}"
    GIT_GEOLITE2_FOLDER = 'https://raw.githubusercontent.com/sapics/ip-location-db/master/geolite2-city'
    GEM_GEOLITE2_CSV = Gem.root('ip_location_db').join('geolite2-city', GEOLITE2_CSV).to_s
    GEM_GEOLITE2_VERSION = Gem.loaded_specs['ip_location_db'].version.to_s

    # TODO fetch from https://github.com/sapics/ip-location-db instead and run as weekly cronjob
    def self.steps
      [
        # :verify_version,
        # :remove_old_data
        :create_countries_and_states,
        :extract_csv_and_split,
        :create_cities_and_ips,
      ]
    end

    def verify_version
      new_version = Gem::Version.new(JSON.parse(open("#{GIT_GEOLITE2_FOLDER}/package.json"))['version'])
      old_version = Gem::Version.new((ActiveRecord::InternalMetadata[:geolite2_version] ||= GEM_GEOLITE2_VERSION))
      if new_version > old_version
        # Truncate tables
        mkdir_p TMP_GEOLITE2_FOLDER, verbose: false
        # IO.copy_stream(open("#{GEOLITE2_GIT_FOLDER}/#{GEOLITE2_CSV}.gz"), "#{TMP_GEOLITE2_FOLDER}/#{GEOLITE2_CSV}.gz")
        # TODO modify GEOLITE2_CITY to a method or ivar
        puts_info "VERSION", "New GeoLite2 version [#{new_version}] downloaded in #{TMP_GEOLITE2_FOLDER} folder"
      else
        sh 'unpigz', '--keep', "#{GEM_GEOLITE2_CSV}.gz", '-c', TMP_GEOLITE2_FOLDER, verbose: false
      end
    end

    def create_countries_and_states
      @countries, states = EXTRA_COUNTRIES.dup, []
      ISO3166::Country.countries.each do |country|
        country_code, country_id = country.alpha2.upcase, country.number
        country.states.each do |code, state|
          state_code, state_code_prefix = code.upcase, "#{country_code}-"
          state_code = [state_code_prefix, state_code].join unless state_code.start_with? state_code_prefix
          state_names = [state.name, Array.wrap(state.unofficial_names), state.translations['en']].flatten.compact.uniq
          states << { code: state_code, names: state_names, country_code: country_code, geo_country_id: country_id }
        end if country_code.in?(SUPPORTED_COUNTRIES)
        @countries << { id: country_id, code: country_code, name: country.name }
      end
      GeoCountry.insert_all! @countries
      GeoState.insert_all! states
      GeoState.all.each(&:update_searches)
    end

    def extract_csv_and_split
      remove_tmp_files
      sh 'unpigz', '--keep', "#{GEM_GEOLITE2_CSV}.gz", verbose: false
      sh 'split', '-l', '100000', '-d', '--additional-suffix', '.csv', GEM_GEOLITE2_CSV, tmp_files_prefix, verbose: false
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
          if state_id.nil? && state_search.size > 1 && country_code.in?(SUPPORTED_COUNTRIES)
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
      GeoIp.insert_all! EXTRA_IPS
      remove_tmp_files
    end

    private

    def remove_tmp_files
      sh 'rm', '--force', GEM_GEOLITE2_CSV, verbose: false
      tmp_files_glob.each{ |file| File.delete(file) }
    end

    def tmp_files_glob
      Dir.glob("#{tmp_files_prefix}*")
    end

    def tmp_files_prefix
      "#{TMP_GEOLITE2_FOLDER}-ipv4-"
    end
  end
end
