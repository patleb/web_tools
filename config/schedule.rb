require 'ext_whenever'

ExtWhenever.setup(self)

# Crontab (ubuntu)
# ----------------
# hourly  --> on minute 17
# daily   --> at 06h25m
# weekly  --> on day 7 (sunday), at 06h47m
# monthly --> on day 01, at 06h52m
# EDT = UTC - (4|5) hours
#
# Examples
# --------
# every :month, at: "start of the month at 4:30 am" do
#   rake 'every_month'
# end
#
# every :week do
#   runner 'EveryWeekJob.perform_later'
# end
#
# every :day, at: '8:00 am' do
#   rake 'every_day'
# end
#
# every :minute do
#   bash 'every_minute.sh'
# end

case @environment
when 'vagrant'
when 'staging', 'production'
  case @application
  when 'web_tools'
    every :sunday, at: '10:11 am' do
      rake 'cron:reboot'
    end

    every :day, at: '8:11 am' do
      rake 'cron:every_day'
    end
  when 'web_cluster'
    every :sunday, at: '10:01 am' do
      rake 'cron:reboot'
    end

    every :day, at: '8:01 am' do
      rake 'cron:cluster:every_day'
    end
  end
end

raise "Setting[:monit_interval] < 1.minute" unless Setting[:monit_interval] >= 1.minute
raise "Setting[:monit_interval] > 20.minutes" unless Setting[:monit_interval] <= 20.minutes

every Setting[:monit_interval] do
  runner 'Monit.capture'
end
