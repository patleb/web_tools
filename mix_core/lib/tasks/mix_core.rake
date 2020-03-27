require_rel 'mix_core'

namespace :mix_core do
  desc 'setup MixCore files'
  task :setup do
    src, dst = Gem.root('mix_core').join('lib/tasks/templates'), Rails.root

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
