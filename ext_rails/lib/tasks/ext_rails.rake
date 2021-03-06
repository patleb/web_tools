require_rel 'ext_rails'

namespace :ext_rails do
  desc 'setup ExtRails files'
  task :setup do
    src, dst = Gem.root('ext_rails').join('lib/tasks/templates'), Rails.root

    unless (dst/'.vagrant/private_key').exist?
      mkdir_p    dst/'.vagrant'
      cp         src/ 'vagrant/private_key', dst/'.vagrant/private_key'
      chmod 600, dst/'.vagrant/private_key'
    end

    %w(cap sun).each do |binstub|
      cp src/'bin'/binstub, dst/'bin'/binstub
    end

    %w(development staging vagrant).each do |env|
      cp  src/"config/environments/#{env}.rb", dst/"config/environments/#{env}.rb"
    end
    write dst/'config/environments/production.rb', template(src/'config/environments/production.rb.erb')

    %w(
      content_security_policy
      cors
    ).each do |init|
      cp src/"config/initializers/#{init}.rb", dst/"config/initializers/#{init}.rb"
    end
    cp src/'config/boot.rb',     dst/'config/boot.rb'
    cp src/'config/schedule.rb', dst/'config/schedule.rb'

    cp      src/'config/provision.yml', dst/'config/provision.yml'
    mkdir_p dst/'config/provision'
    %w(files recipes roles).each do |dir|
      keep  dst/'config/provision'/dir
    end

    %w(
      /vendor/ruby
      /.vagrant/*
      *.box
      /.provision/*
      /.local_repo/*
      /.vscode/*
      /.idea/*
      .editorconfig
      .generators
      .rakeTasks
      /db/dump*
    ).each do |ignore|
      gitignore dst, ignore
    end

    %w(Gemfile Vagrantfile).each do |file|
      write dst/file, template(src/"#{file}.erb")
    end
    write dst/'docker-compose.yml', template(src/'docker-compose.yml.erb')
    cp    src/'Procfile', dst/'Procfile'

    cp      src/'app/mailers/application_mailer.rb', dst/'app/mailers/application_mailer.rb'
    rmtree  dst/'app/assets'
    rm_rf   dst/'lib/assets*'
    rm_rf   dst/'lib/tasks*'
    keep    dst/'lib'
    keep    dst/'app/libraries'
    keep    dst/'app/tasks'
    keep    dst/'db/migrate'
    mkdir_p dst/'doc'
    cp      src/'doc/todo_list.md', dst/'doc/todo_list.md'
    keep    dst/'test/migrations'
    # TODO README.md
  end

  def free_local_ip
    require 'socket'
    network = ''
    networks = [''].concat Socket.getifaddrs.map{ |i| i.addr.ip_address.sub(/\.\d+$/, '') if i.addr.ipv4? }.compact
    loop do
      break unless networks.include?(network)
      network = "192.168.#{rand(4..254)}"
    end
    "#{network}.#{rand(2..254)}"
  end
end

namespace :db do
  task :force_environment_set => :environment do
    Rake::Task['db:environment:set'].invoke rescue nil
  end

  namespace :pg do
    %w(dump restore truncate).each do |name|
      desc "-- [options] #{name.humanize}"
      task name.to_sym => :environment do |t|
        "::Db::Pg::#{name.camelize}".constantize.new(self, t).run!
      end
    end

    desc 'Drop all'
    task :drop_all => :environment do
      sh Sh.psql 'DROP OWNED BY CURRENT_USER', MixTask.config.db_url
    end

    # https://www.dbrnd.com/2018/04/postgresql-9-5-brin-index-maintenance-using-brin_summarize_new_values-add-new-data-page-in-brin-index/
    # https://www.postgresql.org/docs/11/brin-intro.html
    # https://www.postgresql.org/docs/10/functions-admin.html
    desc 'BRIN summarize'
    task :brin_summarize, [:index] => :environment do |t, args|
      sh Sh.psql "SELECT brin_summarize_new_values('#{args[:index]}')", MixTask.config.db_url
    end

    desc 'ANALYZE database'
    task :analyze, [:table] => :environment do |t, args|
      sh Sh.psql "ANALYZE VERBOSE #{args[:table]}", MixTask.config.db_url
    end

    desc 'VACUUM database'
    task :vacuum, [:table, :analyze, :full] => :environment do |t, args|
      analyze = 'ANALYZE' if flag_on? args, :analyze
      full = 'FULL' if flag_on? args, :full
      sh Sh.psql "VACUUM #{full} #{analyze} VERBOSE #{args[:table]}", MixTask.config.db_url
    end
  end
end
Rake::Task['db:drop'].prerequisites.unshift('db:force_environment_set')

namespace :gem do
  desc 'destroy gem'
  task :destroy, [:name] do |t, args|
    name = args[:name]
    except = ENV['EXCEPT'].to_s.split(',')
    `gem list -r '^#{name}$' --remote --all`.match(/\((.+)\)/)[1].split(', ').each do |version|
      if version.in? except
        puts "skipped version [#{version}]"
      else
        puts `gem yank #{name} -v #{version}`
      end
    end
  end
end

namespace :tmp do
  desc 'truncate log'
  task :truncate_log, [:suffix] => :environment do |t, args|
    if (suffix = args[:suffix]).present?
      sh "truncate -s 0 log/#{Rails.env}.log#{suffix}"
    else
      sh "truncate -s 0 log/#{Rails.env}.log"
    end
  end
end
