require_rel 'mix_log'

namespace :log do
  desc 'extract server logs'
  task :extract => :environment do |t|
    MixLog::Extract.new(self, t).run!
  end

  desc 'rollup server logs'
  task :rollup => :environment do |t|
    MixLog::Rollup.new(self, t).run!
  end

  desc 'dump log tables' # 3.6 MB
  task :dump_tables => :environment do |t|
    name = "log_#{Log.maximum(:updated_at).utc.iso8601.tr('-T:Z', '')}"
    Db::Pg::Dump.new(self, t, name: name, includes: ['lib_logs', 'lib_log_messages', 'lib_log_lines']).run!
  end

  desc 'restore log tables'
  task :restore_tables, [:version] => :environment do |t, args|
    file = "db/log_#{args[:version]}.pg.gz"
    file = File.exist?(file) ? file : Dir.glob('db/log_*.pg.gz').sort.last
    Db::Pg::Restore.new(self, t, name: File.basename(file), pg_options: '--disable-triggers --data-only').run!
  end
end
