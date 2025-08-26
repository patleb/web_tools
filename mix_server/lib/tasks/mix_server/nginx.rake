namespace! :nginx do
  namespace :maintenance do
    desc 'Put application in maintenance mode'
    task :enable, [:duration] => :environment do |t, args|
      ENV['MESSAGE'] = maintenance_message(args[:duration])
      nginx_maintenance_push
      ENV['MAINTENANCE'] = 'true'
      nginx_app_push
      ENV['MAINTENANCE'] = nil
    end

    desc 'Put the application out of maintenance mode'
    task :disable => :environment do
      nginx_app_push
    end
  end

  def nginx_maintenance_push
    html = compile 'config/deploy/templates/503.html'
    mv html, Pathname.shared_path('public/503.html')
  end

  def nginx_app_push
    conf = compile 'config/deploy/templates/nginx/app.conf'
    sh "sudo mv #{conf} /etc/nginx/sites-available/#{Rails.stage}"
    nginx_reload
  end

  def nginx_reload
    sh 'sudo systemctl reload nginx' do |ok, _res|
      unless ok
        sh 'sudo systemctl start nginx'
      end
    end
  end
end

if defined? MixJob
  Rake::Task['nginx:maintenance:enable'].enhance ['job:stop']
  Rake::Task['nginx:maintenance:disable'].enhance{ run_task 'job:start' }
end
