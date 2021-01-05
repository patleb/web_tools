require_rel 'mix_log'

namespace :log do
  desc 'extract server logs'
  task :extract => :environment do |t|
    MixLog::ExtractLogs.new(self, t).run!
  end

  desc 'dump log tables' # 3.6 MB
  task :dump_tables => :environment do |t|
    name = "log_#{Log.maximum(:updated_at).utc.iso8601.tr('-T:Z', '')}"
    Db::Pg::Dump.new(self, t, name: name, includes: ['lib_logs', 'lib_log_lines']).run!
  end

  desc 'restore log tables'
  task :restore_tables, [:version] => :environment do |t, args|
    name = "log_#{args[:version]}.pg.gz"
    Db::Pg::Restore.new(self, t, name: name, pg_options: '--disable-triggers --data-only').run!
  end
end
