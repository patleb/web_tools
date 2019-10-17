require_rel 'mr_core'

namespace :mr_core do
  desc 'setup boot.rb, environments, initializers, .gitignore, Gemfile and Vagrantfile files'
  task :setup do
    src, dst = Gem.root('mr_core').join('lib/tasks/templates'), Rails.root

    mkdir dst.join('.vagrant')
    cp src.join('vagrant/private_key'), dst.join('.vagrant/private_key')
    chmod 600, dst.join('.vagrant/private_key')

    cp src.join('config/boot.rb'),      dst.join('config/boot.rb')
    cp src.join('config/schedule.rb'),  dst.join('config/schedule.rb')
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

namespace :ftp do
  desc 'Mount FTP drive'
  task :mount => :environment do
    sh "sudo mkdir -p #{Setting[:ftp_path]}"
    sh "sudo chown -R #{Setting[:deployer_name]}:#{Setting[:deployer_name]} #{Setting[:ftp_path]}"
    options = %W(
      allow_other
      user=#{Setting[:ftp_username]}:#{Setting[:ftp_password]}
    )
    remote_dir = "/#{Rails.application.name}/#{Rails.env}"
    sh <<~CMD.squish
      sudo curlftpfs -o #{options.join(',')},uid=$(id -u #{Setting[:deployer_name]}),gid=$(id -g #{Setting[:deployer_name]})
        #{Setting[:ftp_hostname]}:#{remote_dir} #{Setting[:ftp_path]}
    CMD
  end

  desc 'Unmount FTP drive'
  task :unmount => :environment do
    sh "sudo fusermount -u #{Setting[:ftp_path]}"
  end
end

namespace :ssh do
  desc 'Mount SSH drive'
  task :mount, [:server, :host_path, :mount_path] => :environment do |t, args|
    sh "sudo mkdir -p #{args[:mount_path]}"
    sh "sudo chown -R #{Setting[:deployer_name]}:#{Setting[:deployer_name]} #{args[:mount_path]}"
    options = %W(
      allow_other
      IdentityFile=/home/#{Setting[:deployer_name]}/.ssh/id_rsa
      StrictHostKeyChecking=no
      compression=no
      Ciphers=aes128-ctr
      reconnect
      ServerAliveInterval=15
      ServerAliveCountMax=3
    )
    sh <<~CMD.squish
      sudo sshfs -o #{options.join(',')},uid=$(id -u #{Setting[:deployer_name]}),gid=$(id -g #{Setting[:deployer_name]})
        #{Setting[:deployer_name]}@#{args[:server]}:#{args[:host_path]} #{args[:mount_path]}
    CMD
  end

  desc 'Unmount SSH drive'
  task :unmount, [:path] => :environment do |t, args|
    sh "sudo fusermount -u #{args[:path]}"
  end

  namespace :ftp do
    desc 'Mount SSH-FTP drive'
    task :mount, [:server] => :environment do |t, args|
      Rake::Task['ssh:mount'].invoke(args[:server], Setting[:ftp_path], Setting[:ftp_path])
    end

    desc 'Unmount SSH-FTP drive'
    task :unmount => :environment do
      Rake::Task['ssh:unmount'].invoke(Setting[:ftp_path])
    end
  end
end

namespace :desktop do
  desc "-- [options] Desktop Clean-up Project"
  task :clean_up_project => :environment do |t|
    MrCore::Desktop::CleanUpProject.new(self, t).run
  end

  desc "-- [options] Desktop Update Application"
  task :update_application => :environment do |t|
    MrCore::Desktop::UpdateApplication.new(self, t).run
  end
end

namespace :vpn do
  desc "-- [options] VPN Update IP"
  task :update_ip => :environment do |t|
    MrCore::Vpn::UpdateIp.new(self, t).run
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
