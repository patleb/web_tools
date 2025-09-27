require_dir __FILE__, 'mix_server'

module Try
  class Message < ::StandardError
    def backtrace
      caller
    end
  end
end

namespace :try do
  desc "try send notice"
  task :send_notice => :environment do
    MixServer.with do |config|
      config.skip_notice = false
      Notice.deliver! Try::Message.new, data: { text: 'Text' }
    end
  end
end

namespace :throttler do
  desc 'clear all'
  task :clear_all, [:prefix] => :environment do |t, args|
    Throttler.clear(args[:prefix])
  end
end

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
