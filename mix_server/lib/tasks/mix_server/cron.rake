namespace :cron do
  namespace :cluster do
    desc 'every day cron jobs cluster'
    task :every_day => :environment do
      run_task 'monit:cleanup'
      run_task 'list:reorganize'
      run_task 'clamav:scan'
      run_task 'log:extract'
    end
  end

  desc 'every day cron jobs'
  task :every_day, [:dump] => :environment do |t, args|
    run_task 'monit:cleanup'
    if MixServer.idle? timeout: 20.minutes
      run_task 'certificate:lets_encrypt:create_or_renew'
    end
    run_task 'flash:cleanup'
    run_task 'geo:import_ips'
    run_task 'global:cleanup'
    run_task 'list:reorganize'
    run_task 'clamav:scan'
    run_task 'log:cleanup'
    run_task 'log:extract'
    run_task 'log:rollup'
    run_task 'log:report'
    run_task 'db:pg:dump:rotate' if flag_on? args, :dump
  end

  # TODO add wait functionality for main connection readiness, instead of receiving PG::UnableToSend
  # TODO put cluster in maintenance before rebooting master --> cap_task ...
  # TODO disable master reboot when cluster reboots --> which would make necessary to manage reboots from the master only
  desc 'reboot'
  task :reboot => :environment do
    next unless File.exist?('/var/run/reboot-required')
    next if MixServer.no_reboot_file.exist?

    run_task 'nginx:maintenance:enable'
    unless MixServer.idle? timeout: 2.hours
      next run_task('nginx:maintenance:disable')
    end

    # won't interfere with 5 minutes cron
    until (Time.current.min % 5) == 2
      sleep 10
    end
    run_task 'nginx:maintenance:disable'

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
