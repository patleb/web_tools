namespace :global do
  desc 'cleanup'
  task :cleanup => :environment do
    Global.cleanup
  end
end
