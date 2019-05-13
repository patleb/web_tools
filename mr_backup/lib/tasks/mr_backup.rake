desc "-- [options] Backup"
task :backup => :environment do |t|
  MrBackup::Backup::Base.new(self, t).run
end

namespace :backup do
  desc "-- [options] Backup Git"
  task :git => :environment do |t|
    MrBackup::Backup::Git.new(self, t).run
  end

  desc "-- [options] Backup Partition"
  task :partition => :environment do |t|
    MrBackup::Backup::Partition.new(self, t).run
  end
end

desc "-- [options] Partition"
task :partition => :environment do |t|
  MrBackup::Partition::Base.new(self, t).run
end

namespace :restore do
  desc "-- [options] Restore Archive"
  task :archive => :environment do |t|
    MrBackup::Restore::Archive.new(self, t).run
  end

  desc "-- [options] Restore PostgreSQL"
  task :archive => :environment do |t|
    MrBackup::Restore::PostgreSQL.new(self, t).run
  end

  desc "-- [options] Restore Sync"
  task :archive => :environment do |t|
    MrBackup::Restore::Sync.new(self, t).run
  end
end
