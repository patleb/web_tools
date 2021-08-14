require_rel 'mix_log'

namespace :log do
  desc 'cleanup old log partitions'
  task :cleanup => :environment do |t|
    MixLog::Cleanup.new(self, t).run!
  end

  desc 'extract server logs'
  task :extract => :environment do |t|
    MixLog::Extract.new(self, t).run!
  end

  desc 'rollup server logs'
  task :rollup => :environment do |t|
    MixLog::Rollup.new(self, t).run!
  end

  desc 'report server log errors'
  task :report => :environment do
    LogMessage.report!
  end

  desc 'reset server log alerts'
  task :reset => :environment do
    LogMessage.reset_alerts!
  end

  desc 'dump log tables' # 3.6 MB
  task :dump_tables => :environment do |t|
    name = "log_#{Log.maximum(:updated_at).utc.iso8601.tr('-T:Z', '')}"
    tables = ['lib_servers', 'lib_logs', 'lib_log_messages', 'lib_log_lines*', 'lib_log_rollups']
    Db::Pg::Dump.new(self, t, name: name, includes: tables).run!
  end

  desc 'restore log tables'
  task :restore_tables, [:version] => :environment do |t, args|
    file = "db/log_#{args[:version]}.pg.gz"
    file = File.exist?(file) ? file : Dir.glob('db/log_*.pg.gz').sort.last
    name = File.basename(file)
    Db::Pg::Restore.new(self, t, name: name, data_only: true).run!
  end
end
