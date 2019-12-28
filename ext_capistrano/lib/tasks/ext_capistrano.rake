namespace :ext_capistrano do
  desc 'setup ExtCapistrano files'
  task :setup do
    src, dst = Gem.root('ext_capistrano').join('lib/tasks/templates'), Rails.root

    mkdir_p dst.join('app/tasks')
    touch   dst.join('app/tasks/application.cap')
    cp      src.join('Capfile'), dst.join('Capfile')
    write   dst.join('config/deploy.rb'), template(src.join('config/deploy.rb.erb'))
    mkdir_p dst.join('config/deploy')
    keep    dst.join('config/deploy/templates')
    %w(production staging vagrant).each do |env|
      cp    src.join('config/deploy/production.rb'), dst.join("config/deploy/#{env}.rb")
    end
  end
end
