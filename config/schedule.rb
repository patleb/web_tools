require 'ext_whenever'

ExtWhenever.setup(self)

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
# EDT = UTC - (4|5) hours
# every :day, at: '5am' do
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
