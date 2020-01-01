require_rel 'mr_core'

namespace :mr_core do
  desc 'setup MrCore files'
  task :setup do
    src, dst = Gem.root('mr_core').join('lib/tasks/templates'), Rails.root

    mkdir      dst.join('.vagrant')
    cp         src.join('vagrant/private_key'), dst.join('.vagrant/private_key')
    chmod 600, dst.join('.vagrant/private_key')

    %w(cap sun).each do |binstub|
      cp src.join('bin', binstub), dst.join('bin', binstub)
    end

    cp src.join('config/boot.rb'),     dst.join('config/boot.rb')
    cp src.join('config/schedule.rb'), dst.join('config/schedule.rb')
    %w(development staging vagrant).each do |env|
      cp src.join("config/environments/#{env}.rb"), dst.join("config/environments/#{env}.rb")
    end
    write dst.join('config/environments/production.rb'), template(src.join('config/environments/production.rb.erb'))

    %w(content_security_policy cors zeitwerk).each do |init|
      cp src.join("config/initializers/#{init}.rb"), dst.join("config/initializers/#{init}.rb")
    end

    %w(/vendor/ruby /.provision/* /.vagrant/* /.vscode/* /.idea/* .editorconfig .generators .rakeTasks).each do |ignore|
      gitignore dst, ignore
    end

    %w(Gemfile Vagrantfile).each do |file|
      write dst.join(file), template(src.join("#{file}.erb"))
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
