namespace :cron do
  namespace :cluster do
    desc 'every day cron jobs cluster'
    task :every_day => :environment do
      run_task 'check:cleanup'
      run_task 'list:reorganize'
      run_task 'clamav:scan'
      run_task 'log:extract'
    end
  end

  desc 'every day cron jobs'
  task :every_day, [:dump] => :environment do |t, args|
    run_task 'check:cleanup'
    run_task 'certificate:lets_encrypt:create_or_renew' if defined? MixCertificate
    run_task 'flash:cleanup'  if defined? MixFlash
    run_task 'geo:import_ips' if defined? MixGeo
    run_task 'global:cleanup'
    run_task 'list:reorganize'
    run_task 'clamav:scan'
    run_task 'log:cleanup'
    run_task 'log:extract'
    run_task 'log:rollup'
    run_task 'log:report'
    if flag_on? args, :dump
      run_task 'db:pg:dump',
        base_dir: ExtRails.config.backup_dir,
        split: true,
        md5: true,
        rotate: true,
        excludes: ExtRails.config.backup_excludes.to_a.join(','),
        migrations: false
    end
  end

  desc 'every week cron jobs'
  task :every_week => :environment do
    run_task 'cron:reboot' if File.exist? '/var/run/reboot-required'
  end

  desc 'reboot'
  task :reboot => :environment do
    run_task 'nginx:maintenance:enable'
    started_at = Time.current
    until (ready = Process.passenger.requests.blank?)
      break if (Time.current - started_at) > 2.hours
      sleep ExtRuby.config.memoized_at_threshold
    end
    next run_task('nginx:maintenance:disable') unless ready

    # make sure that Passenger extra workers are killed and no extra rake tasks are running
    min_workers = MixServer.config.minimum_workers + 1 # include the current rake task
    until (ready = Process::Worker.all.select{ |w| w.name == 'ruby' }.size <= min_workers)
      break if (Time.current - started_at) > 2.hours
      sleep ExtRuby.config.memoized_at_threshold
    end
    next run_task('nginx:maintenance:disable') unless ready

    # won't interfere with 5 minutes cron
    until (Time.current.min % 5) == 3
      sleep 10
    end
    run_task 'nginx:maintenance:disable'

    exec 'sudo reboot'
  end
end
