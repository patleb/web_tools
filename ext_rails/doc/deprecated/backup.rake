namespace :backup do
  desc "-- [options] Backup Git"
  task :git => :environment do |t|
    ExtRails::Backup::Git.new(self, t).run!
  end
end
