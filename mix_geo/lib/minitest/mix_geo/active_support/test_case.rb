ActiveSupport::TestCase.class_eval do
  delete_tables.concat(['lib_geo_ips', 'lib_geo_cities', 'lib_geo_states', 'lib_geo_countries'])
end
