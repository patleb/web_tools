namespace :cron do
  namespace :cluster do
    desc 'every day cron jobs cluster'
    task :every_day => :environment do
      run_rake 'monit:cleanup'
      run_rake 'file:cleanup'
      run_rake 'list:reorganize'
      run_rake 'clamav:scan'
      run_rake 'log:extract', ignore: true
    end
  end

  desc 'every day cron jobs'
  task :every_day, [:dump] => :environment do |t, args|
    run_rake 'monit:cleanup'
    run_rake 'certificate:lets_encrypt:create_or_renew' if MixServer.idle? timeout: 20.minutes
    run_rake 'flash:cleanup'
    run_rake 'geo:import_ips', ignore: true
    run_rake 'global:cleanup'
    run_rake 'list:reorganize'
    run_rake 'clamav:scan'
    run_rake 'log:cleanup'
    run_rake 'log:extract', ignore: true
    run_rake 'log:rollup'
    run_rake 'log:report'
    run_rake 'db:pg:dump:rotate' if flag_on? args, :dump
  end
end
