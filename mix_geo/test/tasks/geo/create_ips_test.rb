require './test/test_helper'

module MixGeo
  class CreateIpsTest < Rake::TestCase
    self.task_name = 'geo:import_ips'
    self.use_transactional_tests = false
    self.file_fixture_path = Gem.root('mix_geo').join('test/fixtures/files').to_s

    let(:run_timeout){ 10 }

    test 'geo:import_ips' do
      run_rake remote: false, path: file_fixture_path, version: '2.3.2024121818'
      assert_equal 252, GeoCountry.count
      assert_equal 70, GeoState.count
      assert_equal 'CA-NB', GeoState.find_by_similarity('CA', 'new bruns', 'nouveau').code
      ips = [
        { ip: ['216.82.47.16', '216.82.47.31'], country: 'US', state: 'US-IA', city: 'Hampton' },
        { ip: ['216.82.47.32', '216.82.47.47'], country: 'US', state: 'US-IA', city: 'Jewell' },
        { ip: ['216.82.47.48', '216.82.47.79'], country: 'US', state: 'US-IA', city: 'Coralville' }
      ]
      [(16..31), (32..47), (48..79)].each_with_index do |range, i|
        city = ips[i][:city]
        range = range.map{ |n| "216.82.47.#{n}" }
        range.each do |ip|
          assert_equal city, GeoIp.find_by_ip(ip).geo_city.name
        end
        GeoIp.select_by_ips(range).pluck('geo_city_id').each do |(city_id, *)|
          assert_equal city, GeoCity.find(city_id).name
        end
      end
    end
  end
end
