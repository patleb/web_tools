require_rel 'mr_backend'

namespace :mr_backend do
  desc 'setup boot.rb, environments, initializers, .gitignore, Gemfile and Vagrantfile files'
  task :setup do
    src, dst = Gem.root('mr_backend').join('lib/tasks/templates'), Rails.root

    cp src.join('config/boot.rb'),     dst.join('config/boot.rb')
    cp src.join('config/schedule.rb'), dst.join('config/schedule.rb')
    %w(development staging vagrant).each do |env|
      cp src.join("config/environments/#{env}.rb"), dst.join("config/environments/#{env}.rb")
    end
    write dst.join('config/environments/production.rb'), ERB.template(src.join('config/environments/production.rb.erb'), binding)

    %w(content_security_policy cors).each do |init|
      cp src.join("config/initializers/#{init}.rb"), dst.join("config/initializers/#{init}.rb")
    end

    %w(/vendor/ruby /.provision/* /.vagrant/* /.vscode/* /.idea/* .editorconfig .generators .rakeTasks).each do |ignore|
      gitignore dst, ignore
    end

    %w(Gemfile Vagrantfile).each do |file|
      write dst.join(file), ERB.template(src.join("#{file}.erb"), binding)
    end
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
  desc 'drop pgrest'
  task :drop_pgrest => :environment do
    if Setting[:pgrest_enabled]
      ActiveRecord::Base.connection.exec_query 'DROP SCHEMA IF EXISTS api CASCADE'
      unless Rails.env.test?
        ActiveRecord::Base.connection.exec_query "DROP ROLE IF EXISTS #{Setting[:pgrest_db_username]}"
        ActiveRecord::Base.connection.exec_query 'DROP ROLE IF EXISTS web_anon' rescue nil
      end
    end
  end
end
Rake::Task['db:drop'].enhance ['db:drop_pgrest']

namespace :desktop do
  desc "-- [options] Desktop Clean-up Project"
  task :clean_up_project => :environment do |t|
    MrBackend::Desktop::CleanUpProject.new(self, t).run
  end

  desc "-- [options] Desktop Update Application"
  task :update_application => :environment do |t|
    MrBackend::Desktop::UpdateApplication.new(self, t).run
  end
end

namespace :vpn do
  desc "-- [options] VPN Update IP"
  task :update_ip => :environment do |t|
    MrBackend::Vpn::UpdateIp.new(self, t).run
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
