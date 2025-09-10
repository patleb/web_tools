namespace :system do
  desc 'reboot'
  task :reboot => :environment do
    next unless File.exist?('/var/run/reboot-required')
    next if MixServer.no_reboot_file.exist?

    run_rake 'nginx:maintenance:enable'
    unless MixServer.idle? timeout: 2.hours
      next run_rake('nginx:maintenance:disable')
    end

    # won't interfere with 5 minutes cron
    until (Time.current.min % 5) == 2
      sleep 10
    end
    run_rake 'nginx:maintenance:disable'

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
