namespace :nginx do
  namespace :maintenance do
    desc 'Put application in maintenance mode'
    task :enable, [:env, :duration] => :environment do |t, args|
      time =
        case args[:duration]
        when /\d+\.weeks?$/   then args[:duration].to_i.weeks.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
        when /\d+\.days?$/    then args[:duration].to_i.day.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
        when /\d+\.hours?$/   then args[:duration].to_i.hours.from_now.to_s.sub(/\d{2}:\d{2} UTC$/, '00:00 UTC')
        when /\d+\.minutes?$/ then args[:duration].to_i.minutes.from_now.to_s.sub(/\d{2} UTC$/, '00 UTC')
        when /\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}/ then "#{args[:duration]} UTC"
        when nil
        else
          raise 'invalid :duration'
        end
      ENV['MESSAGE'] = "Should be back around #{time}".gsub(' ', '&nbsp;').gsub('-', '&#8209;') if time
      cap_task 'nginx:maintenance:enable', env: args[:env]
    end

    desc 'Put the application out of maintenance mode'
    task :disable, [:env] => :environment do |t, args|
      cap_task 'nginx:maintenance:disable', env: args[:env]
    end
  end
end
