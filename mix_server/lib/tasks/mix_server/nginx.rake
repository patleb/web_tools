namespace! :nginx do
  namespace :maintenance do
    desc 'Put application in maintenance mode'
    task :enable, [:duration] => :environment do |t, args|
      ENV['MESSAGE'] = nginx_maintenance_message(args[:duration])
      nginx_maintenance_push
      ENV['MAINTENANCE'] = true
      nginx_app_push
      ENV['MAINTENANCE'] = false
    end

    desc 'Put the application out of maintenance mode'
    task :disable => :environment do
      nginx_app_push
    end
  end

  def nginx_maintenance_push
    html = compile 'config/deploy/templates/503.html'
    mv html, MixServer.shared_dir.join('public/503.html')
  end

  def nginx_app_push
    conf = compile 'config/deploy/templates/nginx/app.conf'
    sh "sudo mv #{conf} /etc/nginx/sites-available/#{MixServer.deploy_dir}"
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
