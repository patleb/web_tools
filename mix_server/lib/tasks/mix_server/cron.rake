namespace :cron do
  namespace :cluster do
    desc 'every day cron jobs cluster'
    task :every_day => :environment do
      run_task 'monit:cleanup'
      run_task 'file:cleanup'
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
end
