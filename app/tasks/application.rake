# require_dir __FILE__
#
# desc 'daily cron jobs'
# task :every_day => :environment do
#   # do stuff
# end

namespace :sandbox do
  desc 'Build sandbox for development'
  task :build => :environment do
    raise 'only in dev, test or virtual env' unless Rails.env.local? || Rails.env.virtual?
    `bin/rails db:environment:set RAILS_ENV=#{Rails.env}`
    run_rake 'db:drop'
    run_rake 'db:create'
    run_rake 'db:migrate'
    run_rake 'user:create', Setting[:authorized_keys].first.split(' ').last, 'passpasspass', 'deployer', true
    run_rake 'task:delete_or_create_all'
    run_rake 'page:create_all'
  end
end
