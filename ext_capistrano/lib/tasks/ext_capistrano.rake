namespace :ext_capistrano do
  desc 'setup Capfile, deploy'
  task :setup do
    src, dst = Gem.root('ext_capistrano').join('lib/tasks/templates'), Rails.root

    mkdir_p dst.join('app/tasks')
    touch   dst.join('app/tasks/application.cap')
    cp      src.join('Capfile'), dst.join('Capfile')
    write   dst.join('config/deploy.rb'), ERB.template(src.join('config/deploy.rb.erb'), binding)
    mkdir_p dst.join('config/deploy')
    mkdir_p dst.join('config/deploy/templates')
    touch   dst.join('config/deploy/templates/.keep')
    %w(production staging vagrant).each do |env|
      cp    src.join('config/deploy/production.rb'), dst.join("config/deploy/#{env}.rb")
    end
  end
end
