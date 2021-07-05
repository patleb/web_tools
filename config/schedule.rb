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
# every :month, at: "start of the month at 4:30am" do
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
when 'staging'
when 'production'
end
