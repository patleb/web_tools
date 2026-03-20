require_dir __FILE__, 'mix_server'

namespace :try do
  desc "try send notice"
  task :send_notice => :environment do
    MixServer.with do |config|
      config.skip_notice = false
      Notice.deliver! Try::Message.new, data: { text: 'Text' }
    end
  end

  %w(raise_exception sleep sleep_long).each do |name|
    desc "try #{name.tr('_', ' ')}"
    task name.to_sym => :environment do |t|
      "Try::#{name.camelize}".constantize.new(self, t).run!
    end
  end

  desc "try send email later"
  task :send_email_later => :environment do
    run_rake 'try:send_email', :later
  end

  desc "try send email"
  task :send_email, [:later] => :environment do |t, args|
    email = (defined?(ApplicationMailer) ? ApplicationMailer : LibMailer).healthcheck
    if flag_on? args, :later
      email.deliver_later
    else
      email.deliver_now
    end
  end

  desc "try private ip"
  task :private_ip => :environment do
    puts Process.host.private_ip
  end

  namespace :cluster do
    desc "try cluster private ip"
    task :private_ip => :environment do
      sun_rake 'try:private_ip'
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
    run_rake 'task:create_all'
    run_rake 'page:create_all' unless flag_on? args, :no_pages
  end
end

namespace :server do
  desc 'refresh private ip'
  task :refresh_private_ip => :environment do
    next unless (change = Process.host.refresh_private_ip)
    Server.update_private_ip! *change
    puts "if you're using 'db/postgres-{postgres}/private_network', then in 'config/sunzistrano.yml':"
    puts "  add 'db/postgres-{postgres}/private_network_refresh-{refresh_private_ip}' to 'recipes',"
    puts "  set 'refresh_private_ip' (ex.: 2026_03_01) and run 'sun provision #{Setting.env}'"
    puts "if 'master_ip' is a 'private_ip' and you're using 'deploy/private_dns-system' with 'cloud_cluster' at 'true', then in 'config/sunzistrano.yml':"
    puts "  add 'deploy/private_dns_refresh-{refresh_master_ip}' to 'recipes',"
    puts "  set 'refresh_master_ip' (ex.: 2026_03_01) and run 'sun provision #{Setting.env}'"
  end

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
