require_rel 'mix_geo'

namespace :geo do
  desc 'import geo ips' # takes about 6 minutes on 8 cores or 20 minutes on 1 core
  task :import_ips => :environment do |t|
    MixGeo::CreateIps.new(self, t).run!
  end

  desc 'dump geo tables'
  task :dump_tables => :environment do |t|
    name = "geo_#{ActiveRecord::InternalMetadata[:geolite2_version].tr('.', '-')}"
    Db::Pg::Dump.new(self, t, name: name, includes: MixGeo::CreateIps::GEO_TABLES).run!
  end

  desc 'restore geo tables' # takes about 35 seconds
  task :restore_tables, [:version] => :environment do |t, args|
    name = "geo_#{args[:version].tr('.', '-')}.pg.gz"
    Db::Pg::Restore.new(self, t, name: name, pg_options: '--disable-triggers --data-only').run!
    ActiveRecord::InternalMetadata[:geolite2_version] = args[:version]
    GeoState.all.each(&:update_searches)
  end
end
