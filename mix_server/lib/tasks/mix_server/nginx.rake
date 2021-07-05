namespace :nginx do
  def nginx_maintenance_message(duration = nil)
    time =
      case duration
      when /\d+\.weeks?$/   then duration.to_i.weeks.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
      when /\d+\.days?$/    then duration.to_i.day.from_now.to_s.sub(/\d{2}:\d{2}:\d{2} UTC$/, '20:00:00 UTC')
      when /\d+\.hours?$/   then duration.to_i.hours.from_now.to_s.sub(/\d{2}:\d{2} UTC$/, '00:00 UTC')
      when /\d+\.minutes?$/ then duration.to_i.minutes.from_now.to_s.sub(/\d{2} UTC$/, '00 UTC')
      when /\d{4}-\d{1,2}-\d{1,2} \d{2}:\d{2}/ then "#{duration} UTC"
      when nil
      else
        raise 'invalid :duration'
      end
    "Should be back around #{time}".gsub(' ', '&nbsp;').gsub('-', '&#8209;') if time
  end

  def nginx_maintenance_push
    html = compile '503.html'
    mv html, MixServer.config.shared_dir.join('public/503.html')
  end

  def nginx_app_push
    conf = compile 'config/deploy/templates/nginx/app.conf'
    sh "sudo mv #{conf} /etc/nginx/sites-available/#{MixServer.config.deploy_dir}"
    nginx_reload
  end

  def nginx_reload
    sh 'sudo systemctl reload nginx' do |ok, _res|
      unless ok
        sh 'sudo systemctl start nginx'
      end
    end
  end

  namespace :maintenance do
    desc 'Put application in maintenance mode'
    task :enable, [:env, :duration] => :environment do |t, args|
      ENV['MESSAGE'] = nginx_maintenance_message(args[:duration])
      if args[:env].present?
        cap_task 'nginx:maintenance:enable', env: args[:env]
      else
        nginx_maintenance_push
        ENV['MAINTENANCE'] = true
        nginx_app_push
      end
    end

    desc 'Put the application out of maintenance mode'
    task :disable, [:env] => :environment do |t, args|
      if args[:env].present?
        cap_task 'nginx:maintenance:disable', env: args[:env]
      else
        nginx_app_push
      end
    end
  end
end
