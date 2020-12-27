require_rel 'mix_geo'

namespace :geo do
  desc 'import geo ips'
  task :import_ips => :environment do |t|
    MixGeo::CreateIps.new(self, t).run! # takes about 6 minutes on 8 cores or 20 minutes on 1 core
  end

  desc 'dump geo tables'
  task :dump_tables => :environment do |t|
    tables = ['lib_geo_cities', 'lib_geo_countries', 'lib_geo_ips', 'lib_geo_states']
    Db::Pg::Dump.new(self, t, name: 'geo', includes: tables).run!
  end

  desc 'restore geo tables'
  task :restore_tables => :environment do |t|
    ENV['PG_OPTIONS'] = '--disable-triggers --data-only'
    Db::Pg::Restore.new(self, t, name: 'geo.pg.gz').run! # takes about 35 seconds
  end

  desc 'index geo states'
  task :index_states_searches => :environment do
    GeoState.all.each(&:update_searches)
  end
end
