namespace :ext_capistrano do
  desc 'setup ExtCapistrano files'
  task :setup do
    src, dst = Gem.root('ext_capistrano').join('lib/tasks/templates'), Rails.root

    mkdir_p dst/'app/tasks'
    touch   dst/'app/tasks/application.cap'
    cp      src/'Capfile', dst/'Capfile'
    write   dst/'config/deploy.rb', template(src/'config/deploy.rb.erb')
    mkdir_p dst/'config/deploy'
    keep    dst/'config/deploy/templates'
    %w(production staging vagrant).each do |env|
      cp    src/'config/deploy/production.rb', dst/"config/deploy/#{env}.rb"
    end
  end
end
