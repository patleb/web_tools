require_rel 'mix_geo'

namespace :geo do
  desc 'import geo ips' # takes about 2m40s on 8 cores (GeoIp: 279 MB including 110 MB of indexes)
  task :import_ips => :environment do |t|
    MixGeo::CreateIps.new(self, t).run!
  end

  desc 'dump geo tables'
  task :dump_tables => :environment do |t|
    name = "geo_#{Global[:geolite2_version].tr('.', '-')}"
    Db::Pg::Dump.new(self, t, name: name, includes: MixGeo::CreateIps::GEO_TABLES).run!
  end

  desc 'restore geo tables' # takes about 35 seconds
  task :restore_tables, [:version] => :environment do |t, args|
    file = "db/geo_#{args[:version]&.tr('.', '-')}.pg.gz"
    file = File.exist?(file) ? file : Dir.glob('db/geo_*.pg.gz').sort.last
    file = File.basename(file)
    Db::Pg::Restore.new(self, t, name: file, pg_options: '--disable-triggers --data-only').run!
    Global[:geolite2_version] = file[/[\d-]+/].tr('-', '.')
    GeoState.all.each(&:update_searches)
  end
end
