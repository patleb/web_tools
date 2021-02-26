namespace :flash do
  desc 'cleanup old flashes'
  task :cleanup => :environment do
    Flash.cleanup
  end
end
