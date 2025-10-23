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
  task :build, [:no_pages] => :environment do |t, args|
    raise 'only in dev, test or virtual env' unless Rails.env.local? || Rails.env.virtual?
    `bin/rails db:environment:set RAILS_ENV=#{Rails.env}`
    run_rake 'db:drop'
    run_rake 'db:create'
    run_rake 'db:migrate'
    run_rake 'user:create', Setting[:authorized_keys].first.split(' ').last, 'passpasspass', 'deployer', true
    run_rake 'task:delete_or_create_all'
    run_rake 'page:create_all' unless flag_on? args, :no_pages
  end
end

namespace :system do
  desc 'reboot'
  task :reboot => :environment do
    next unless File.exist?('/var/run/reboot-required')
    next if MixServer.no_reboot_file.exist?

    run_bash 'nginx.maintenance_enable'
    unless MixServer.idle? timeout: 2.hours
      next run_bash 'nginx.maintenance_disable'
    end

    # won't interfere with 5 minutes cron
    until (Time.current.min % 5) == 2
      sleep 10
    end
    run_bash 'nginx.maintenance_disable'

    exec 'sudo reboot'
  end

  namespace :reboot do
    desc 'disable reboot'
    task :disable => :environment do
      MixServer.no_reboot_file.touch
    end

    desc 'enable reboot'
    task :enable => :environment do
      MixServer.no_reboot_file.delete(false)
    end
  end
end
