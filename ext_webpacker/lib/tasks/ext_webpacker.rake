namespace :ext_webpacker do
  desc 'setup ExtWebpacker files'
  task :setup do
    src, dst = Gem.root('ext_webpacker').join('lib/tasks/templates'), Rails.root

    %w(webpack webpack-dev-server).each do |webpack|
      cp src/'bin'/webpack, dst/'bin'/webpack
    end
    cp src/'app/javascript/packs/application.js', dst/'app/javascript/packs/application.js'
    %w(app config images mixins stylesheets).each do |dir|
      keep dst/'app/javascript'/dir
    end
    cp src/'config/webpacker.yml', dst/'config/webpacker.yml'
    %w(environment staging vagrant).each do |env|
      cp src/"config/webpack/#{env}.js", dst/"config/webpack/#{env}.js"
    end
    cp src/'babel.config.js', dst/'babel.config.js'

    sh 'yarn remove @rails/ujs', verbose: false rescue nil
  end

  namespace :symlinks do
    desc 'update symlinks'
    task :update do
      require 'ext_webpacker/webpacker'
    end
  end
end
